"use client"

import { useState, useEffect } from "react"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog"
import { Search, Trash } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, getDocs, doc, deleteDoc } from "firebase/firestore"
import { format } from "date-fns"

type Support = {
  id: string
  email: string
  message: string
  createdAt: string
}

export default function SupportPage() {
  const [searchTerm, setSearchTerm] = useState("")
  const [supports, setSupports] = useState<Support[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedSupport, setSelectedSupport] = useState<Support | null>(null)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [supportToDelete, setSupportToDelete] = useState<Support | null>(null)

  useEffect(() => {
    const fetchSupports = async () => {
      try {
        const supportCollection = collection(db, "support")
        const supportSnapshot = await getDocs(supportCollection)

        const supportData = supportSnapshot.docs.map((doc) => {
          const data = doc.data()
          let createdAt = "Unknown"

          if (data.createdAt) {
            if (typeof data.createdAt === "string") {
              const parsedDate = new Date(data.createdAt)
              createdAt = isNaN(parsedDate.getTime()) ? "Unknown" : format(parsedDate, "yyyy-MM-dd HH:mm")
            } else if (data.createdAt.toDate) {
              createdAt = format(new Date(data.createdAt.toDate()), "yyyy-MM-dd HH:mm")
            }
          }

          return {
            id: doc.id,
            email: data.email || "No email",
            message: data.message || "No message",
            createdAt,
          }
        })

        setSupports(supportData)
      } catch (error) {
        console.error("Error fetching supports:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchSupports()
  }, [])

  const filteredSupports = supports.filter(
    (support) =>
      support.email.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const handleViewDetails = (support: Support) => {
    setSelectedSupport(support)
  }

  const handleCloseDialog = () => {
    setSelectedSupport(null)
  }

  const handleReply = (email: string) => {
    const gmailUrl = `https://mail.google.com/mail/u/0/?hl=en#inbox?compose=new&to=${encodeURIComponent(email)}`
    window.open(gmailUrl, "_blank")
  }

  const handleDeleteSupport = async () => {
    if (supportToDelete) {
      try {
        await deleteDoc(doc(db, "support", supportToDelete.id))
        setSupports(supports.filter((support) => support.id !== supportToDelete.id))
        setDeleteDialogOpen(false)
      } catch (error) {
        console.error("Error deleting support:", error)
        alert("Failed to delete support. Please try again.")
      }
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold tracking-tight">Support Reclamations</h1>
      </div>

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search by email..."
            className="pl-8"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Email</TableHead>
              <TableHead>Created At</TableHead>
              <TableHead className="w-[100px]"></TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={3} className="h-24 text-center">
                  <div className="flex justify-center">
                    <div className="h-6 w-6 animate-spin rounded-full border-b-2 border-madina-blue"></div>
                  </div>
                </TableCell>
              </TableRow>
            ) : filteredSupports.length > 0 ? (
              filteredSupports.map((support) => (
                <TableRow key={support.id}>
                  <TableCell className="font-medium">{support.email}</TableCell>
                  <TableCell>{support.createdAt}</TableCell>
                  <TableCell>
                    <div className="flex space-x-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleViewDetails(support)}
                      >
                        See Details
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="text-red-600 hover:text-red-800"
                        onClick={() => {
                          setSupportToDelete(support)
                          setDeleteDialogOpen(true)
                        }}
                      >
                        <Trash className="h-4 w-4" />
                        <span className="sr-only">Delete support</span>
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={3} className="h-24 text-center">
                  No support reclamations found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {selectedSupport && (
        <Dialog open={!!selectedSupport} onOpenChange={handleCloseDialog}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Support Reclamation Details</DialogTitle>
            </DialogHeader>
            <div className="py-4">
              <p className="text-sm text-muted-foreground">Email: {selectedSupport.email}</p>
              <p className="text-sm text-muted-foreground">Created At: {selectedSupport.createdAt}</p>
              <p className="mt-2 font-medium">Message:</p>
              <p className="text-sm">{selectedSupport.message}</p>
            </div>
            <DialogFooter>
              <Button
                variant="default"
                onClick={() => handleReply(selectedSupport.email)}
              >
                Reply
              </Button>
              <Button variant="outline" onClick={handleCloseDialog}>
                Close
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {supportToDelete && (
        <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Confirm Deletion</DialogTitle>
            </DialogHeader>
            <div className="py-4">
              <p>Are you sure you have completely replied to the user?</p>
            </div>
            <DialogFooter>
              <Button
                variant="destructive"
                onClick={handleDeleteSupport}
              >
                Yes, Delete
              </Button>
              <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
                Cancel
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </div>
  )
}