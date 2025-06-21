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
import { Search, MoreHorizontal, PlusCircle, Calendar, Eye, Edit, Trash } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, getDocs, deleteDoc, doc } from "firebase/firestore"
import { format } from "date-fns"

type Blog = {
  id: string
  title: string
  excerpt: string
  content: string
  images: string[]
  date: string
  author: string
  views: number
}

export default function BlogsPage() {
  const [searchTerm, setSearchTerm] = useState("")
  const [blogs, setBlogs] = useState<Blog[]>([])
  const [loading, setLoading] = useState(true)
  const [language, setLanguage] = useState<"ar" | "en" | "fr">(
    (typeof window !== "undefined" && localStorage.getItem("language") as "ar" | "en" | "fr") || "en"
  )

  useEffect(() => {
    const fetchBlogs = async () => {
      try {
        const blogsCollection = collection(db, "blogs")
        const blogsSnapshot = await getDocs(blogsCollection)

        const blogsData = blogsSnapshot.docs.map((doc) => {
          const data = doc.data()
          const title = data.title?.[language] || data.title?.en || "Untitled Blog"
          const excerpt =
            data.excerpt?.[language] ||
            data.excerpt?.en ||
            (data.content?.[language]?.substring(0, 100) + "..." || "No content")
          const content = data.content?.[language] || data.content?.en || ""

          return {
            id: doc.id,
            title,
            excerpt,
            content,
            images: data.images?.length > 0 ? data.images : ["/placeholder.svg?height=200&width=300"],
            date: data.createdAt
              ? format(new Date(data.createdAt.toDate()), "yyyy-MM-dd")
              : format(new Date(), "yyyy-MM-dd"),
            author: data.author || "Unknown Author",
            views: data.views || 0,
          }
        })

        setBlogs(blogsData)
      } catch (error) {
        console.error("Error fetching blogs:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchBlogs()
  }, [language])

  useEffect(() => {
    localStorage.setItem("language", language)
  }, [language])

  const filteredBlogs = blogs.filter(
    (blog) =>
      blog.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      blog.excerpt.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const handleDeleteBlog = async (blogId: string) => {
    if (confirm("Are you sure you want to delete this blog post?")) {
      try {
        await deleteDoc(doc(db, "blogs", blogId))
        setBlogs(blogs.filter((blog) => blog.id !== blogId))
      } catch (error) {
        console.error("Error deleting blog:", error)
        alert("Failed to delete blog. Please try again.")
      }
    }
  }

  return (
    <div className="flex flex-col gap-4" dir="auto">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold tracking-tight">Blogs</h1>
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
            <Link href="/dashboard/blogs/new" className="flex items-center gap-2">
              <PlusCircle className="h-4 w-4" />
              New Blog Post
            </Link>
          </Button>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search blogs..."
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
        ) : filteredBlogs.length > 0 ? (
          filteredBlogs.map((blog) => (
            <Card key={blog.id} className="overflow-hidden">
              <Swiper navigation modules={[Navigation]} className="h-48 w-full">
                {blog.images.map((image, index) => (
                  <SwiperSlide key={index}>
                    <div className="relative h-48 w-full">
                      <Image
                        src={image}
                        alt={`Blog Image ${index + 1}`}
                        fill
                        className="object-cover"
                      />
                    </div>
                  </SwiperSlide>
                ))}
              </Swiper>

              <CardHeader>
                <CardTitle>{blog.title}</CardTitle>
                <CardDescription className="flex items-center gap-2 text-xs">
                  <Calendar className="h-3 w-3" />
                  {blog.date}
                  <span className="mx-1">•</span>
                  <Eye className="h-3 w-3" />
                  {blog.views} views
                </CardDescription>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted-foreground">{blog.excerpt}</p>
              </CardContent>
              <CardFooter className="flex justify-between">
                <p className="text-xs text-muted-foreground">By {blog.author}</p>
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
                    <DropdownMenuItem>
                      <Eye className="mr-2 h-4 w-4" />
                      View
                    </DropdownMenuItem>
                    <DropdownMenuItem asChild>
                      <Link href={`/dashboard/blogs/edit/${blog.id}`}>
                        <Edit className="mr-2 h-4 w-4" />
                        Edit
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      className="text-red-600"
                      onClick={() => handleDeleteBlog(blog.id)}
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
            <p className="text-muted-foreground">No blogs found.</p>
          </div>
        )}
      </div>
    </div>
  )
}