import { type NextRequest, NextResponse } from "next/server"
import { db } from "@/lib/firebase"
import { collection, getDocs } from "firebase/firestore"

// You'll need to install twilio: npm install twilio
// and add your Twilio credentials to environment variables
const accountSid = process.env.TWILIO_ACCOUNT_SID
const authToken = process.env.TWILIO_AUTH_TOKEN
const twilioPhoneNumber = process.env.TWILIO_PHONE_NUMBER

export async function POST(request: NextRequest) {
  try {
    const { eventTitle, eventDate, eventLocation } = await request.json()

    if (!accountSid || !authToken || !twilioPhoneNumber) {
      return NextResponse.json({ error: "Twilio credentials not configured" }, { status: 500 })
    }

    // Initialize Twilio client
    const twilio = require("twilio")(accountSid, authToken)

    // Fetch all users from Firestore
    const usersSnapshot = await getDocs(collection(db, "users"))
    const phoneNumbers: string[] = []

    usersSnapshot.forEach((doc) => {
      const userData = doc.data()
      if (userData.phoneNumber) {
        let phoneNumber = userData.phoneNumber.toString().trim()

        // Remove any non-digit characters except +
        phoneNumber = phoneNumber.replace(/[^\d+]/g, "")

        // Handle Tunisian phone numbers (+216)
        const digitsOnly = phoneNumber.replace(/\D/g, "")
        
        if (phoneNumber.startsWith("+216")) {
          // Already has Tunisian country code
          if (digitsOnly.length === 11) { // +216 + 8 digits = 11 total digits
            phoneNumbers.push(phoneNumber)
          } else {
            console.log(`Skipping invalid Tunisian phone number: ${userData.phoneNumber} (wrong length)`)
          }
        } else if (phoneNumber.startsWith("216") && digitsOnly.length === 11) {
          // Has country code but missing +
          phoneNumbers.push("+" + phoneNumber)
        } else if (digitsOnly.length === 8) {
          // Tunisian number without country code (8 digits)
          phoneNumbers.push("+216" + digitsOnly)
        } else if (phoneNumber.startsWith("+216") && digitsOnly.length === 11) {
          // Valid Tunisian format
          phoneNumbers.push(phoneNumber)
        } else {
          console.log(`Skipping invalid phone number format: ${userData.phoneNumber} (expected Tunisian format)`)
        }
      }
    })

    console.log(`Found ${phoneNumbers.length} valid phone numbers:`, phoneNumbers)

    if (phoneNumbers.length === 0) {
      return NextResponse.json({ message: "No phone numbers found" }, { status: 200 })
    }

    // Create SMS message
    const message = `🎉 New Event Alert!\n\n${eventTitle}\n📅 ${eventDate}\n📍 ${eventLocation}\n\nCheck the app for more details!`

    // Send SMS to all users
    const smsPromises = phoneNumbers.map(async (phoneNumber) => {
      try {
        await twilio.messages.create({
          body: message,
          from: twilioPhoneNumber,
          to: phoneNumber,
        })
        return { phoneNumber, status: "sent" }
      } catch (error) {
        console.error(`Failed to send SMS to ${phoneNumber}:`, error)
        return { phoneNumber, status: "failed", error: error.message }
      }
    })

    const results = await Promise.all(smsPromises)
    const successCount = results.filter((r) => r.status === "sent").length
    const failureCount = results.filter((r) => r.status === "failed").length

    return NextResponse.json({
      message: `SMS notifications sent`,
      totalUsers: phoneNumbers.length,
      successful: successCount,
      failed: failureCount,
      results,
    })
  } catch (error) {
    console.error("Error sending SMS notifications:", error)
    return NextResponse.json({ error: "Failed to send SMS notifications" }, { status: 500 })
  }
}
