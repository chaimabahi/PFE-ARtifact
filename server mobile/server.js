const express = require("express");
const cors = require("cors");
const nodemailer = require("nodemailer");
const stripe = require("stripe")("your sk here");

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(cors());

// Configure Nodemailer transporter
const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 587,
  secure: false, 
  auth: {
    user: "artifact.golden.medina@gmail.com", 
    pass: "aper rffm vdkn tmiu",
  },
});

// Create a payment intent
app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount, currency } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    console.log("Client Secret:", paymentIntent.client_secret);

    res.json({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Send verification email with Nodemailer
app.post("/send-verification-email", async (req, res) => {
  const { email, passcode, time } = req.body;

  if (!email || !passcode || !time) {
    return res.status(400).send("Missing required fields: email, passcode, or time");
  }

  const mailOptions = {
    from: '"ARtifact" <artifact.golden.medina@gmail.com>',
    to: email,
    subject: "Verification Code",
    html: `
     <div style="font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px;">
      <div style="max-width: 500px; margin: auto; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); padding: 30px;">
        <h2 style="text-align: center; color: #333;">🔐 Email Verification</h2>
        <p style="font-size: 16px; color: #555;">
          Hello,
        </p>
        <p style="font-size: 16px; color: #555;">
          Use the verification code below to complete your action. This code is valid until <strong>${time}</strong>.
        </p>
        <div style="text-align: center; margin: 30px 0;">
          <span style="display: inline-block; font-size: 24px; font-weight: bold; letter-spacing: 2px; color: #4CAF50; background: #f0f0f0; padding: 15px 25px; border-radius: 8px;">
            ${passcode}
          </span>
        </div>
        <p style="font-size: 14px; color: #999; text-align: center;">
          If you did not request this code, you can safely ignore this email.
        </p>
        <p style="font-size: 14px; color: #999; text-align: center; margin-top: 20px;">
          — ARtifact Team
        </p>
      </div>
    </div>
    `,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log("Verification email sent:", info.response);
    res.status(200).send("Email sent successfully");
  } catch (error) {
    console.error("Error sending verification email:", error);
    res.status(500).send("Failed to send email: " + error.message);
  }
});

// Send password reset email with Nodemailer
app.post("/send-password-reset-email", async (req, res) => {
  console.log("Received request for /send-password-reset-email:", req.body); // Debug log
  const { email, passcode, time } = req.body;

  if (!email || !passcode || !time) {
    return res.status(400).send("Missing required fields: email, passcode, or time");
  }

  const mailOptions = {
    from: '"ARtifact" <artifact.golden.medina@gmail.com>',
    to: email,
    subject: "Password Reset Request",
    html: `
     <div style="font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px;">
      <div style="max-width: 500px; margin: auto; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); padding: 30px;">
        <h2 style="text-align: center; color: #333;">🔑 Password Reset</h2>
        <p style="font-size: 16px; color: #555;">
          Hello,
        </p>
        <p style="font-size: 16px; color: #555;">
          You requested to reset your password. Use the code below to proceed with resetting your password. This code is valid until <strong>${time}</strong>.
        </p>
        <div style="text-align: center; margin: 30px 0;">
          <span style="display: inline-block; font-size: 24px; font-weight: bold; letter-spacing: 2px; color: #4CAF50; background: #f0f0f0; padding: 15px 25px; border-radius: 8px;">
            ${passcode}
          </span>
        </div>
        <p style="font-size: 14px; color: #999; text-align: center;">
          If you did not request a password reset, you can safely ignore this email.
        </p>
        <p style="font-size: 14px; color: #999; text-align: center; margin-top: 20px;">
          — ARtifact Team
        </p>
      </div>
    </div>
    `,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log("Password reset email sent:", info.response);
    res.status(200).send("Password reset email sent successfully");
  } catch (error) {
    console.error("Error sending password reset email:", error);
    res.status(500).send("Failed to send password reset email: " + error.message);
  }
});

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

//dep
