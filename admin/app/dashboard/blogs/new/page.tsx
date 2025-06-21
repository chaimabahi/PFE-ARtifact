"use client"

import type React from "react"
import { useState } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Card, CardContent } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ArrowLeft, Upload, X } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, addDoc, serverTimestamp } from "firebase/firestore"

export default function NewBlogPage() {
  const router = useRouter()
  const [formData, setFormData] = useState<{
    title: { ar: string; en: string; fr: string }
    excerpt: { ar: string; en: string; fr: string }
    content: { ar: string; en: string; fr: string }
  }>({
    title: { ar: "", en: "", fr: "" },
    excerpt: { ar: "", en: "", fr: "" },
    content: { ar: "", en: "", fr: "" },
  })
  const [images, setImages] = useState<string[]>([])
  const [uploading, setUploading] = useState(false)
  const [saving, setSaving] = useState(false)

  const handleInputChange = (
    field: "title" | "excerpt" | "content",
    language: "ar" | "en" | "fr",
    value: string,
  ) => {
    setFormData((prev) => ({
      ...prev,
      [field]: { ...prev[field], [language]: value },
    }))
  }

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return

    setUploading(true)
    try {
      const file = e.target.files[0]
      const formData = new FormData()
      formData.append("image", file)

      const response = await fetch(
        `https://api.imgbb.com/1/upload?key=a53af6f55580a94556f22efc4bfa326c`,
        {
          method: "POST",
          body: formData,
        },
      )

      const data = await response.json()
      if (data.data && data.data.url) {
        setImages([...images, data.data.url])
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

  const removeImage = (index: number) => {
    setImages((prev) => prev.filter((_, i) => i !== index))
  }

  const isFormValid = () => {
    return ["ar", "en", "fr"].every((lang) =>
      formData.title[lang as "ar" | "en" | "fr"] &&
      formData.excerpt[lang as "ar" | "en" | "fr"] &&
      formData.content[lang as "ar" | "en" | "fr"]
    )
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)

    try {
      if (!isFormValid()) {
        alert("You cannot post this blog until all fields (title, excerpt, content) are filled in English, French, and Arabic.")
        setSaving(false)
        return
      }

      const blogData = {
        title: {
          ar: formData.title.ar,
          en: formData.title.en,
          fr: formData.title.fr,
        },
        excerpt: {
          ar: formData.excerpt.ar,
          en: formData.excerpt.en,
          fr: formData.excerpt.fr,
        },
        content: {
          ar: formData.content.ar,
          en: formData.content.en,
          fr: formData.content.fr,
        },
        images,
        author: "Admin",
        views: 0,
        createdAt: serverTimestamp(),
      }

      await addDoc(collection(db, "blogs"), blogData)
      alert("Blog post created successfully!")
      router.push("/dashboard/blogs")
    } catch (error) {
      console.error("Error creating blog post:", error)
      alert("Failed to create blog post. Please try again.")
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center gap-4">
        <Button variant="outline" size="icon" onClick={() => router.push("/dashboard/blogs")}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <h1 className="text-3xl font-bold tracking-tight">New Blog Post</h1>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <Tabs defaultValue="en" className="w-full">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="en">English</TabsTrigger>
            <TabsTrigger value="fr">Français</TabsTrigger>
            <TabsTrigger value="ar">العربية</TabsTrigger>
          </TabsList>
          {(["en", "fr", "ar"] as const).map((lang) => (
            <TabsContent key={lang} value={lang} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor={`title-${lang}`}>Title ({lang.toUpperCase()})</Label>
                <Input
                  id={`title-${lang}`}
                  placeholder={`Enter blog title in ${lang.toUpperCase()}`}
                  value={formData.title[lang]}
                  onChange={(e) => handleInputChange("title", lang, e.target.value)}
                  dir={lang === "ar" ? "rtl" : "ltr"}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor={`excerpt-${lang}`}>Excerpt ({lang.toUpperCase()})</Label>
                <Textarea
                  id={`excerpt-${lang}`}
                  placeholder={`Brief summary in ${lang.toUpperCase()}...`}
                  value={formData.excerpt[lang]}
                  onChange={(e) => handleInputChange("excerpt", lang, e.target.value)}
                  dir={lang === "ar" ? "rtl" : "ltr"}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor={`content-${lang}`}>Content ({lang.toUpperCase()})</Label>
                <Textarea
                  id={`content-${lang}`}
                  placeholder={`Write your blog content in ${lang.toUpperCase()}...`}
                  value={formData.content[lang]}
                  onChange={(e) => handleInputChange("content", lang, e.target.value)}
                  dir={lang === "ar" ? "rtl" : "ltr"}
                  required
                />
              </div>
            </TabsContent>
          ))}
        </Tabs>

        <div className="space-y-2">
          <Label>Images</Label>
          <div className="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-4">
            {images.map((image, index) => (
              <div key={index} className="relative rounded-md overflow-hidden h-40">
                <img src={image} alt={`Blog image ${index + 1}`} className="h-full w-full object-cover" />
                <Button
                  variant="destructive"
                  size="icon"
                  className="absolute right-2 top-2 h-6 w-6"
                  onClick={() => removeImage(index)}
                  type="button"
                >
                  <X className="h-3 w-3" />
                </Button>
              </div>
            ))}
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
                      disabled={uploading}
                    />
                  </div>
                </label>
              </CardContent>
            </Card>
          </div>
        </div>

        <div className="flex justify-end gap-4">
          <Button variant="outline" onClick={() => router.push("/dashboard/blogs")} type="button">
            Cancel
          </Button>
          <Button type="submit" disabled={saving || uploading || !isFormValid()}>
            {saving ? "Saving..." : "Publish Blog Post"}
          </Button>
        </div>
      </form>
    </div>
  )
}