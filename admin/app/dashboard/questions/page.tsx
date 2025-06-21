"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Search, PlusCircle } from "lucide-react"
import Link from "next/link"
import CategoryTabs from "./components/CategoryTabs"
import { fetchCategoriesThemesAndLevels, fetchQuestions } from "../../../lib/quiz"
import { Category, Theme, Level, Question } from "../../../lib/types"

export default function QuestionsPage() {
  const [searchTerm, setSearchTerm] = useState("")
  const [activeCategory, setActiveCategory] = useState<string>("")
  const [categories, setCategories] = useState<Category[]>([])
  const [themes, setThemes] = useState<Record<string, Theme[]>>({})
  const [levels, setLevels] = useState<Record<string, Level[]>>({})
  const [questions, setQuestions] = useState<Record<string, Record<string, Question[]>>>({})
  const [loading, setLoading] = useState(true)
  const [selectedTheme, setSelectedTheme] = useState<string | null>(null)
  const [selectedLevel, setSelectedLevel] = useState<string | null>(null)
  const [language, setLanguage] = useState<"ar" | "en" | "fr">(
    (typeof window !== "undefined" && localStorage.getItem("language") as "ar" | "en" | "fr") || "en"
  )

  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true)
        const { categoriesData, themesData, levelsData } = await fetchCategoriesThemesAndLevels()
        setCategories(categoriesData)
        setThemes(themesData)
        setLevels(levelsData)
        setActiveCategory(categoriesData.length > 0 ? categoriesData[0].id : "default")
      } catch (error) {
        console.error("Error loading data:", error)
      } finally {
        setLoading(false)
      }
    }
    loadData()
  }, [])

  useEffect(() => {
    if (Object.keys(themes).length > 0 && Object.keys(levels).length > 0) {
      fetchQuestions(themes, levels).then(setQuestions).catch((error) => {
        console.error("Error fetching questions:", error)
      })
    }
  }, [themes, levels])

  useEffect(() => {
    localStorage.setItem("language", language)
  }, [language])

  return (
    <div className={`flex flex-col gap-4 ${language === "ar" ? "dir-rtl" : "dir-ltr"}`}>
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold tracking-tight">Themes and Questions</h1>
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
            <Link href="/dashboard/questions/new" className="flex items-center gap-2">
              <PlusCircle className="h-4 w-4" />
              Add Question
            </Link>
          </Button>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder={selectedTheme ? "Search questions..." : "Search themes..."}
            className="pl-8"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      <CategoryTabs
        categories={categories}
        activeCategory={activeCategory}
        setActiveCategory={setActiveCategory}
        themes={themes}
        levels={levels}
        questions={questions}
        searchTerm={searchTerm}
        selectedTheme={selectedTheme}
        setSelectedTheme={setSelectedTheme}
        selectedLevel={selectedLevel}
        setSelectedLevel={setSelectedLevel}
        language={language}
        loading={loading}
        setQuestions={setQuestions}
      />
    </div>
  )
}