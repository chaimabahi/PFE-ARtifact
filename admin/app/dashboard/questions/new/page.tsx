"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { fetchCategoriesThemesAndLevels, addCategory, addTheme, addLevel, addQuestion, fetchQuestions } from "../../../../lib/quiz"
import { Category, Theme, Level, Question } from "../../../../lib/types"
import Link from "next/link"
import { ArrowLeft } from "lucide-react"

export default function AddQuizContent() {
  const [categories, setCategories] = useState<Category[]>([])
  const [themes, setThemes] = useState<Record<string, Theme[]>>({})
  const [levels, setLevels] = useState<Record<string, Level[]>>({})
  const [questions, setQuestions] = useState<Record<string, Record<string, Question[]>>>({})
  const [selectedCategory, setSelectedCategory] = useState<string>("")
  const [selectedTheme, setSelectedTheme] = useState<string>("")
  const [selectedLevel, setSelectedLevel] = useState<string>("")
  const [newCategoryName, setNewCategoryName] = useState("")
  const [newThemeTitle, setNewThemeTitle] = useState({ ar: "", en: "", fr: "" })
  const [newThemeImage, setNewThemeImage] = useState("")
  const [newLevelId, setNewLevelId] = useState("")
  const [newQuestion, setNewQuestion] = useState({
    question: { ar: "", en: "", fr: "" },
    options: { ar: ["", "", "", ""], en: ["", "", "", ""], fr: ["", "", "", ""] },
    correct: { ar: "", en: "", fr: "" },
    difficulty: "easy",
  })
  const [loading, setLoading] = useState(true)
  const [step, setStep] = useState<"category" | "theme" | "level" | "question">("category")
  const [isNewCategory, setIsNewCategory] = useState(false)

  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true)
        const { categoriesData, themesData, levelsData } = await fetchCategoriesThemesAndLevels()
        setCategories(categoriesData)
        setThemes(themesData)
        setLevels(levelsData)
        const questionsData = await fetchQuestions(themesData, levelsData)
        setQuestions(questionsData)
      } catch (error) {
        console.error("Error loading data:", error)
      } finally {
        setLoading(false)
      }
    }
    loadData()
  }, [])

  const handleAddCategory = async () => {
    if (!newCategoryName) return alert("Please provide a category name.")

    try {
      const newCategory = await addCategory({ name: newCategoryName })
      setCategories((prev) => [...prev, newCategory])
      setThemes((prev) => ({ ...prev, [newCategory.id]: [] }))
      setLevels((prev) => ({ ...prev }))
      setSelectedCategory(newCategory.id)
      setNewCategoryName("")
      setIsNewCategory(true)
      setStep("theme")
    } catch (error) {
      console.error("Error adding category:", error)
      alert("Failed to add category. Please try again.")
    }
  }

  const handleAddTheme = async () => {
    if (!selectedCategory) return alert("Please select a category first.")
    if (!newThemeTitle.en) return alert("Please provide at least an English title for the theme.")

    try {
      const newTheme = await addTheme(selectedCategory, {
        title: newThemeTitle,
        image: newThemeImage || "/placeholder.svg?height=200&width=300",
      })
      setThemes((prev) => ({
        ...prev,
        [selectedCategory]: [...(prev[selectedCategory] || []), newTheme],
      }))
      setLevels((prev) => ({
        ...prev,
        [newTheme.id]: [],
      }))
      setSelectedTheme(newTheme.id)
      setNewThemeTitle({ ar: "", en: "", fr: "" })
      setNewThemeImage("")
      setStep("level")
    } catch (error) {
      console.error("Error adding theme:", error)
      alert("Failed to add theme. Please try again.")
    }
  }

  const handleAddLevel = async () => {
    if (!newLevelId) return alert("Please provide a level ID.")

    try {
      const newLevel = await addLevel(selectedCategory, selectedTheme, { id: newLevelId })
      setLevels((prev) => ({
        ...prev,
        [selectedTheme]: [...(prev[selectedTheme] || []), newLevel],
      }))
      setSelectedLevel(newLevel.id)
      setNewLevelId("")
      setStep("question")
    } catch (error) {
      console.error("Error adding level:", error)
      alert("Failed to add level. Please try again.")
    }
  }

  const getNextQuestionId = () => {
    const existingQuestions = questions[selectedTheme]?.[selectedLevel] || []
    if (existingQuestions.length === 0) return "q1"
    const questionNumbers = existingQuestions
      .map((q) => parseInt(q.id.replace("q", ""), 10))
      .filter((num) => !isNaN(num))
    const maxNumber = questionNumbers.length > 0 ? Math.max(...questionNumbers) : 0
    return `q${maxNumber + 1}`
  }

  const handleAddQuestion = async () => {
    try {
      const questionId = getNextQuestionId()
      const questionData: Omit<Question, "id" | "isComplete" | "createdAt"> = {
        question: newQuestion.question,
        options: newQuestion.options,
        correct: newQuestion.correct,
        difficulty: newQuestion.difficulty,
      }
      const addedQuestion = await addQuestion(selectedCategory, selectedTheme, selectedLevel, questionData, questionId)
      setQuestions((prev) => {
        const updated = { ...prev }
        if (!updated[selectedTheme]) updated[selectedTheme] = {}
        if (!updated[selectedTheme][selectedLevel]) updated[selectedTheme][selectedLevel] = []
        updated[selectedTheme][selectedLevel].push(addedQuestion)
        return updated
      })
      alert(`Question ${questionId} added successfully!`)
      setNewQuestion({
        question: { ar: "", en: "", fr: "" },
        options: { ar: ["", "", "", ""], en: ["", "", "", ""], fr: ["", "", "", ""] },
        correct: { ar: "", en: "", fr: "" },
        difficulty: "easy",
      })
    } catch (error) {
      console.error("Error adding question:", error)
      alert("Failed to add question. Please try again.")
    }
  }

  if (loading) {
    return (
      <div className="flex h-40 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-madina-blue"></div>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold tracking-tight">Add Quiz Content</h1>
        <Button asChild variant="outline">
          <Link href="/dashboard/questions" className="flex items-center gap-2">
            <ArrowLeft className="h-4 w-4" />
            Back to Questions
          </Link>
        </Button>
      </div>

      {step === "category" && (
        <Card>
          <CardHeader>
            <CardTitle>Select or Add Category</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label>Select Existing Category</Label>
              <Select onValueChange={(value) => {
                setSelectedCategory(value)
                setIsNewCategory(false)
                setStep("theme")
              }}>
                <SelectTrigger>
                  <SelectValue placeholder="Select a category" />
                </SelectTrigger>
                <SelectContent>
                  {categories.map((category) => (
                    <SelectItem key={category.id} value={category.id}>
                      {category.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Add New Category</Label>
              <Input
                placeholder="Category Name"
                value={newCategoryName}
                onChange={(e) => setNewCategoryName(e.target.value)}
              />
              <Button onClick={handleAddCategory}>Add Category</Button>
            </div>
          </CardContent>
        </Card>
      )}

      {step === "theme" && (
        <Card>
          <CardHeader>
            <CardTitle>{isNewCategory ? "Add Theme to New Category" : "Select or Add Theme"}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {!isNewCategory && (
              <div>
                <Label>Select Existing Theme</Label>
                <Select value={selectedTheme} onValueChange={(value) => {
                  setSelectedTheme(value)
                  setStep("level")
                }}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select a theme" />
                  </SelectTrigger>
                  <SelectContent>
                    {(themes[selectedCategory] || []).map((theme) => (
                      <SelectItem key={theme.id} value={theme.id}>
                        {theme.title.en || "Untitled Theme"}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}
            {selectedCategory && (
              <div className="space-y-2">
                <Label>Add New Theme to {categories.find(cat => cat.id === selectedCategory)?.name}</Label>
                <Input
                  placeholder="Theme Title (Arabic)"
                  value={newThemeTitle.ar}
                  onChange={(e) => setNewThemeTitle({ ...newThemeTitle, ar: e.target.value })}
                />
                <Input
                  placeholder="Theme Title (English)"
                  value={newThemeTitle.en}
                  onChange={(e) => setNewThemeTitle({ ...newThemeTitle, en: e.target.value })}
                />
                <Input
                  placeholder="Theme Title (French)"
                  value={newThemeTitle.fr}
                  onChange={(e) => setNewThemeTitle({ ...newThemeTitle, fr: e.target.value })}
                />
                <Input
                  placeholder="Theme Image URL (optional)"
                  value={newThemeImage}
                  onChange={(e) => setNewThemeImage(e.target.value)}
                />
                <Button onClick={handleAddTheme}>Add Theme</Button>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {step === "level" && (
        <Card>
          <CardHeader>
            <CardTitle>{isNewCategory ? "Add Level to New Theme" : "Select Existing Level"}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {isNewCategory ? (
              <div className="space-y-2">
                <Label>Add New Level</Label>
                <Input
                  placeholder="Level ID (e.g., Beginner)"
                  value={newLevelId}
                  onChange={(e) => setNewLevelId(e.target.value)}
                />
                <Button onClick={handleAddLevel}>Add Level</Button>
              </div>
            ) : (
              <div>
                <Label>Select Existing Level</Label>
                <Select value={selectedLevel} onValueChange={(value) => {
                  setSelectedLevel(value)
                  setStep("question")
                }}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select a level" />
                  </SelectTrigger>
                  <SelectContent>
                    {(levels[selectedTheme] || []).map((level) => (
                      <SelectItem key={level.id} value={level.id}>
                        {level.id}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {step === "question" && (
        <Card>
          <CardHeader>
            <CardTitle>Add Question to {selectedLevel}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Question Text</Label>
              <Input
                placeholder="Arabic"
                value={newQuestion.question.ar}
                onChange={(e) =>
                  setNewQuestion({
                    ...newQuestion,
                    question: { ...newQuestion.question, ar: e.target.value },
                  })
                }
              />
              <Input
                placeholder="English"
                value={newQuestion.question.en}
                onChange={(e) =>
                  setNewQuestion({
                    ...newQuestion,
                    question: { ...newQuestion.question, en: e.target.value },
                  })
                }
              />
              <Input
                placeholder="French"
                value={newQuestion.question.fr}
                onChange={(e) =>
                  setNewQuestion({
                    ...newQuestion,
                    question: { ...newQuestion.question, fr: e.target.value },
                  })
                }
              />
            </div>

            {["ar", "en", "fr"].map((lang) => (
              <div key={lang} className="space-y-2">
                <Label>{lang.toUpperCase()} Options</Label>
                {newQuestion.options[lang].map((option, index) => (
                  <Input
                    key={`${lang}-${index}`}
                    placeholder={`Option ${index + 1}`}
                    value={option}
                    onChange={(e) => {
                      const newOptions = [...newQuestion.options[lang]]
                      newOptions[index] = e.target.value
                      setNewQuestion({
                        ...newQuestion,
                        options: { ...newQuestion.options, [lang]: newOptions },
                      })
                    }}
                  />
                ))}
              </div>
            ))}

            <div className="space-y-2">
              <Label>Correct Answer</Label>
              <Input
                placeholder="Arabic"
                value={newQuestion.correct.ar}
                onChange={(e) =>
                  setNewQuestion({
                    ...newQuestion,
                    correct: { ...newQuestion.correct, ar: e.target.value },
                  })
                }
              />
              <Input
                placeholder="English"
                value={newQuestion.correct.en}
                onChange={(e) =>
                  setNewQuestion({
                    ...newQuestion,
                    correct: { ...newQuestion.correct, en: e.target.value },
                  })
                }
              />
              <Input
                placeholder="French"
                value={newQuestion.correct.fr}
                onChange={(e) =>
                  setNewQuestion({
                    ...newQuestion,
                    correct: { ...newQuestion.correct, fr: e.target.value },
                  })
                }
              />
            </div>

            <div className="space-y-2">
              <Label>Difficulty</Label>
              <Select
                value={newQuestion.difficulty}
                onValueChange={(value) =>
                  setNewQuestion({ ...newQuestion, difficulty: value })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select difficulty" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="easy">Easy</SelectItem>
                  <SelectItem value="medium">Medium</SelectItem>
                  <SelectItem value="hard">Hard</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <Button onClick={handleAddQuestion}>Add Question</Button>
          </CardContent>
        </Card>
      )}
    </div>
  )
}