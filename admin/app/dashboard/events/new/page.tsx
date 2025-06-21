"use client"

import type React from "react"
import { useState } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Card, CardContent } from "@/components/ui/card"
import { ArrowLeft, Upload, X, CalendarIcon, MapPin } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, addDoc, Timestamp } from "firebase/firestore"
import { Checkbox } from "@/components/ui/checkbox"
import DatePicker from "react-datepicker"
import "react-datepicker/dist/react-datepicker.css"

export default function NewEventPage() {
  const router = useRouter()
  const [title, setTitle] = useState("")
  const [about, setAbout] = useState("")
  const [includes, setIncludes] = useState("")
  const [eventDate, setEventDate] = useState<Date | null>(new Date())
  const [location, setLocation] = useState("")
  const [locationLat, setLocationLat] = useState("")
  const [locationLng, setLocationLng] = useState("")
  const [isFree, setIsFree] = useState(true)
  const [isNew, setIsNew] = useState(false)
  const [imageURL, setImageURL] = useState<string>("")
  const [uploading, setUploading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [sendingSMS, setSendingSMS] = useState(false)

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return

    setUploading(true)
    try {
      const file = e.target.files[0]
      const formData = new FormData()
      formData.append("image", file)

      const response = await fetch(`https://api.imgbb.com/1/upload?key=a53af6f55580a94556f22efc4bfa326c`, {
        method: "POST",
        body: formData,
      })

      const data = await response.json()
      if (data.data && data.data.url) {
        setImageURL(data.data.url)
      } else {
        throw new Error("Failed to upload image")
      }
    } catch (error) {
      console.error("Error uploading image:", error)
      alert("Failed to upload image. Please try again.")
    } finally {
      setUploading(false)
    }
  }

  const removeImage = () => {
    setImageURL("")
  }

  const isFormValid = () => {
    return (
      title &&
      about &&
      eventDate &&
      location &&
      locationLat &&
      locationLng &&
      Number.parseFloat(locationLat) !== Number.NaN &&
      Number.parseFloat(locationLng) !== Number.NaN
    )
  }

  const sendSMSNotifications = async (eventData: any) => {
    setSendingSMS(true)
    try {
      const response = await fetch("/api/send-sms", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          eventTitle: eventData.title,
          eventDate: eventData.eventDateTime.toDate().toLocaleDateString(),
          eventLocation: eventData.location,
        }),
      })

      const result = await response.json()

      if (response.ok) {
        console.log("SMS notifications sent:", result)
        alert(`SMS notifications sent to ${result.successful} users successfully!`)
      } else {
        console.error("Failed to send SMS notifications:", result.error)
        alert("Event created successfully, but failed to send SMS notifications.")
      }
    } catch (error) {
      console.error("Error sending SMS notifications:", error)
      alert("Event created successfully, but failed to send SMS notifications.")
    } finally {
      setSendingSMS(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)

    try {
      if (!isFormValid()) {
        alert("Please fill all required fields (title, about, date/time, location, latitude, longitude).")
        setSaving(false)
        return
      }

      const eventData = {
        title: title,
        about: about,
        includes: includes || "",
        eventDateTime: eventDate ? Timestamp.fromDate(eventDate) : null,
        location: location,
        locationLat: Number.parseFloat(locationLat),
        locationLng: Number.parseFloat(locationLng),
        isFree: isFree,
        isNew: isNew,
        imageURL: imageURL || "https://via.placeholder.com/300x200",
        participants: 0,
      }

      // Create the event in Firestore
      await addDoc(collection(db, "events"), eventData)

      // Send SMS notifications to all users
      await sendSMSNotifications(eventData)

      alert("Event created successfully!")
      router.push("/dashboard/events")
    } catch (error) {
      console.error("Error creating event:", error)
      alert("Failed to create event. Please try again.")
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center gap-4">
        <Button variant="outline" size="icon" onClick={() => router.push("/dashboard/events")}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <h1 className="text-3xl font-bold tracking-tight">New Event</h1>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="title">Title</Label>
            <Input
              id="title"
              placeholder="Enter event title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="about">About</Label>
            <Textarea
              id="about"
              placeholder="Describe the event..."
              value={about}
              onChange={(e) => setAbout(e.target.value)}
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="includes">Includes (comma-separated)</Label>
            <Input
              id="includes"
              placeholder="e.g., -food -drinks -workshop"
              value={includes}
              onChange={(e) => setIncludes(e.target.value)}
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label>
              <div className="flex items-center gap-2">
                <CalendarIcon className="h-4 w-4" />
                Date & Time
              </div>
            </Label>
            <DatePicker
              selected={eventDate}
              onChange={(date) => setEventDate(date)}
              showTimeSelect
              timeFormat="HH:mm"
              timeIntervals={15}
              dateFormat="MMMM d, yyyy h:mm aa"
              className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="location">
              <div className="flex items-center gap-2">
                <MapPin className="h-4 w-4" />
                Location
              </div>
            </Label>
            <Input
              id="location"
              placeholder="Event location"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="locationLat">Location Latitude</Label>
            <Input
              id="locationLat"
              type="number"
              step="0.000001"
              placeholder="37.7749"
              value={locationLat}
              onChange={(e) => setLocationLat(e.target.value)}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="locationLng">Location Longitude</Label>
            <Input
              id="locationLng"
              type="number"
              step="0.000001"
              placeholder="-122.4194"
              value={locationLng}
              onChange={(e) => setLocationLng(e.target.value)}
              required
            />
          </div>

          <div className="space-y-2">
            <div className="flex items-center space-x-2">
              <Checkbox id="isFree" checked={isFree} onCheckedChange={(checked) => setIsFree(!!checked)} />
              <Label htmlFor="isFree">Free Event</Label>
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex items-center space-x-2">
              <Checkbox id="isNew" checked={isNew} onCheckedChange={(checked) => setIsNew(!!checked)} />
              <Label htmlFor="isNew">Mark as New</Label>
            </div>
          </div>
        </div>

        <div className="space-y-2">
          <Label>Image</Label>
          <div className="grid grid-cols-1 gap-4">
            {imageURL && (
              <div className="relative rounded-md overflow-hidden h-40">
                <img src={imageURL || "/placeholder.svg"} alt="Event image" className="h-full w-full object-cover" />
                <Button
                  variant="destructive"
                  size="icon"
                  className="absolute right-2 top-2 h-6 w-6"
                  onClick={removeImage}
                  type="button"
                >
                  <X className="h-3 w-3" />
                </Button>
              </div>
            )}
            <Card className="flex h-40 flex-col items-center justify-center">
              <CardContent className="flex h-full w-full flex-col items-center justify-center p-6">
                <label className="w-full h-full">
                  <div
                    className={`flex flex-col items-center justify-center w-full h-full border-2 border-dashed rounded-md cursor-pointer ${
                      uploading ? "opacity-50" : "hover:bg-muted/50"
                    }`}
                  >
                    {uploading ? (
                      <div className="flex items-center gap-2">
                        <div className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></div>
                        <span>Uploading...</span>
                      </div>
                    ) : (
                      <div className="flex flex-col items-center gap-2">
                        <Upload className="h-6 w-6" />
                        <span>Upload Image</span>
                      </div>
                    )}
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={handleImageUpload}
                      disabled={uploading || imageURL !== ""}
                    />
                  </div>
                </label>
              </CardContent>
            </Card>
          </div>
        </div>

        <div className="flex justify-end gap-4">
          <Button variant="outline" onClick={() => router.push("/dashboard/events")} type="button">
            Cancel
          </Button>
          <Button type="submit" disabled={saving || uploading || sendingSMS || !isFormValid()}>
            {saving ? "Creating Event..." : sendingSMS ? "Sending Notifications..." : "Create Event"}
          </Button>
        </div>
      </form>
    </div>
  )
}
