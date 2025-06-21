"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import Image from "next/image"
import { Swiper, SwiperSlide } from "swiper/react"
import { Navigation } from "swiper/modules"
import "swiper/css"
import "swiper/css/navigation"

import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog"
import { Label } from "@/components/ui/label"
import { Checkbox } from "@/components/ui/checkbox"
import { Search, MoreHorizontal, PlusCircle, Calendar, MapPin, Users, Edit, Trash, Eye } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, getDocs, deleteDoc, doc, updateDoc } from "firebase/firestore"
import { format, parse } from "date-fns"

type Event = {
  id: string
  title: string
  about: string
  imageURL: string[]
  eventDateTime: string
  location: string
  participants: number
  isFree: boolean
}

export default function EventsPage() {
  const [searchTerm, setSearchTerm] = useState("")
  const [events, setEvents] = useState<Event[]>([])
  const [loading, setLoading] = useState(true)
  const [language, setLanguage] = useState<"ar" | "en" | "fr">(
    (typeof window !== "undefined" && localStorage.getItem("language") as "ar" | "en" | "fr") || "en"
  )
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false)
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null)
  const [editForm, setEditForm] = useState({
    title: "",
    about: "",
    location: "",
    eventDateTime: "",
    participants: 0,
    isFree: false,
  })

  useEffect(() => {
    const fetchEvents = async () => {
      try {
        const eventsCollection = collection(db, "events")
        const eventsSnapshot = await getDocs(eventsCollection)

        const eventsData = eventsSnapshot.docs.map((doc) => {
          const data = doc.data()
          const title = data.title?.[language] || data.title?.en || data.title || "Untitled Event"
          const about =
            data.about?.[language] ||
            data.about?.en ||
            (data.about?.substring(0, 100) + "..." || "No description")

          // Ensure imageURL is an array of valid URLs
          const imageURL = Array.isArray(data.imageURL)
            ? data.imageURL.filter((url: string) => typeof url === "string" && url.trim() !== "")
            : typeof data.imageURL === "string" && data.imageURL.trim() !== ""
              ? [data.imageURL]
              : [];

          return {
            id: doc.id,
            title,
            about,
            imageURL: imageURL.length > 0 ? imageURL : ["/placeholder.svg?height=200&width=300"],
            eventDateTime: data.eventDateTime
              ? format(new Date(data.eventDateTime.toDate()), "PPP 'at' p")
              : format(new Date(), "PPP 'at' p"),
            location: data.location || "Unknown Location",
            participants: data.participants || 0,
            isFree: data.isFree || false,
          }
        })

        setEvents(eventsData)
      } catch (error) {
        console.error("Error fetching events:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchEvents()
  }, [language])

  useEffect(() => {
    localStorage.setItem("language", language)
  }, [language])

  const filteredEvents = events.filter(
    (event) =>
      event.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      event.about.toLowerCase().includes(searchTerm.toLowerCase())
  )

  const handleDeleteEvent = async (eventId: string) => {
    if (confirm("Are you sure you want to delete this event?")) {
      try {
        await deleteDoc(doc(db, "events", eventId))
        setEvents(events.filter((event) => event.id !== eventId))
      } catch (error) {
        console.error("Error deleting event:", error)
        alert("Failed to delete event. Please try again.")
      }
    }
  }

  const openEditDialog = (event: Event) => {
    setSelectedEvent(event)
    setEditForm({
      title: event.title,
      about: event.about,
      location: event.location,
      eventDateTime: event.eventDateTime,
      participants: event.participants,
      isFree: event.isFree,
    })
    setIsEditDialogOpen(true)
  }

  const handleEditSubmit = async () => {
    if (!selectedEvent) return

    try {
      const eventRef = doc(db, "events", selectedEvent.id)
      await updateDoc(eventRef, {
        title: { [language]: editForm.title },
        about: { [language]: editForm.about },
        location: editForm.location,
        eventDateTime: parse(editForm.eventDateTime, "PPP 'at' p", new Date()),
        participants: editForm.participants,
        isFree: editForm.isFree,
      })

      setEvents(
        events.map((event) =>
          event.id === selectedEvent.id
            ? {
                ...event,
                title: editForm.title,
                about: editForm.about,
                location: editForm.location,
                eventDateTime: editForm.eventDateTime,
                participants: editForm.participants,
                isFree: editForm.isFree,
              }
            : event
        )
      )
      setIsEditDialogOpen(false)
      setSelectedEvent(null)
    } catch (error) {
      console.error("Error updating event:", error)
      alert("Failed to update event. Please try again.")
    }
  }

  return (
    <div className="flex flex-col gap-4" dir="auto">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold tracking-tight">Events</h1>
        <div className="flex items-center gap-4">
          <select
            value={language}
            onChange={(e) => setLanguage(e.target.value as "ar" | "en" | "fr")}
            className="rounded-md border border-input bg-background px-3 py-2 text-sm"
          >
            <option value="en">English</option>
            <option value="fr">Français</option>
            <option value="ar">العربية</option>
          </select>
          <Button asChild>
            <Link href="/dashboard/events/new" className="flex items-center gap-2">
              <PlusCircle className="h-4 w-4" />
              New Event
            </Link>
          </Button>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search events..."
            className="pl-8"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {loading ? (
          <div className="col-span-full flex h-40 items-center justify-center">
            <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-madina-blue"></div>
          </div>
        ) : filteredEvents.length > 0 ? (
          filteredEvents.map((event) => (
            <Card key={event.id} className="overflow-hidden">
              <Swiper navigation modules={[Navigation]} className="h-48 w-full">
                {event.imageURL.map((image, index) => (
                  <SwiperSlide key={index}>
                    <div className="relative h-48 w-full">
                      <Image
                        src={image || "/placeholder.svg?height=200&width=300"} // Fallback for safety
                        alt={`Event Image ${index + 1}`}
                        fill
                        className="object-cover"
                      />
                    </div>
                  </SwiperSlide>
                ))}
              </Swiper>

              <CardHeader>
                <CardTitle>{event.title}</CardTitle>
                <CardDescription className="flex items-center gap-2 text-xs">
                  <Calendar className="h-3 w-3" />
                  {event.eventDateTime}
                  <span className="mx-1">•</span>
                  <MapPin className="h-3 w-3" />
                  {event.location}
                </CardDescription>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted-foreground">{event.about}</p>
              </CardContent>
              <CardFooter className="flex justify-between">
                <div className="flex items-center gap-4">
                  <p className="text-xs text-muted-foreground">
                    <Users className="inline h-3 w-3 mr-1" />
                    {event.participants} participants
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {event.isFree ? "Free" : "Paid"}
                  </p>
                </div>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="icon">
                      <MoreHorizontal className="h-4 w-4" />
                      <span className="sr-only">Open menu</span>
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuLabel>Actions</DropdownMenuLabel>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem asChild>
                      <Link href={`/dashboard/events/${event.id}`} className="flex items-center">
                        <Eye className="mr-2 h-4 w-4" />
                        View
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      className="flex items-center"
                      onClick={() => openEditDialog(event)}
                    >
                      <Edit className="mr-2 h-4 w-4" />
                      Edit
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      className="text-red-600"
                      onClick={() => handleDeleteEvent(event.id)}
                    >
                      <Trash className="mr-2 h-4 w-4" />
                      Delete
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </CardFooter>
            </Card>
          ))
        ) : (
          <div className="col-span-full flex h-40 items-center justify-center rounded-md border border-dashed">
            <p className="text-muted-foreground">No events found.</p>
          </div>
        )}
      </div>

      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Edit Event</DialogTitle>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="title" className="text-right">
                Title
              </Label>
              <Input
                id="title"
                value={editForm.title}
                onChange={(e) => setEditForm({ ...editForm, title: e.target.value })}
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="about" className="text-right">
                About
              </Label>
              <Input
                id="about"
                value={editForm.about}
                onChange={(e) => setEditForm({ ...editForm, about: e.target.value })}
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="location" className="text-right">
                Location
              </Label>
              <Input
                id="location"
                value={editForm.location}
                onChange={(e) => setEditForm({ ...editForm, location: e.target.value })}
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="eventDateTime" className="text-right">
                Date & Time
              </Label>
              <Input
                id="eventDateTime"
                value={editForm.eventDateTime}
                onChange={(e) => setEditForm({ ...editForm, eventDateTime: e.target.value })}
                className="col-span-3"
                placeholder="MMM d, yyyy 'at' h:mm a"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="participants" className="text-right">
                Participants
              </Label>
              <Input
                id="participants"
                type="number"
                value={editForm.participants}
                onChange={(e) => setEditForm({ ...editForm, participants: parseInt(e.target.value) || 0 })}
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="isFree" className="text-right">
                Free
              </Label>
              <Checkbox
                id="isFree"
                checked={editForm.isFree}
                onCheckedChange={(checked) => setEditForm({ ...editForm, isFree: !!checked })}
                className="col-span-3"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsEditDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleEditSubmit}>Save</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}