import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
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
  DialogDescription,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { HelpCircle, MoreHorizontal, Edit, Trash, AlertCircle } from "lucide-react"
import { Question } from "../../../../lib/types"
import { deleteQuestion, updateQuestion } from "../../../../lib/quiz"

interface QuestionListProps {
  questions: Question[]
  searchTerm: string
  language: "ar" | "en" | "fr"
  categoryId: string
  themeId: string
  levelId: string
  themeTitle: string
  setSelectedLevel: (value: string | null) => void
  setQuestions: React.Dispatch<React.SetStateAction<Record<string, Record<string, Question[]>>>>
}

export default function QuestionList({
  questions,
  searchTerm,
  language,
  categoryId,
  themeId,
  levelId,
  themeTitle,
  setSelectedLevel,
  setQuestions,
}: QuestionListProps) {
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false)
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false)
  const [currentQuestion, setCurrentQuestion] = useState<Question | null>(null)
  const [questionToDelete, setQuestionToDelete] = useState<string | null>(null)
  const [formData, setFormData] = useState({
    question: "",
    options: ["", "", "", ""],
    correct: "",
    difficulty: "easy",
  })

  const filteredQuestions = questions.filter((question) =>
    (question.question[language] || "").toLowerCase().includes(searchTerm.toLowerCase())
  )

  const handleEditClick = (question: Question) => {
    setCurrentQuestion(question)
    setFormData({
      question: question.question[language] || "",
      options: question.options[language] || ["", "", "", ""],
      correct: question.correct[language] || "",
      difficulty: question.difficulty,
    })
    setIsEditDialogOpen(true)
  }

  const handleSave = async () => {
    if (!currentQuestion) return

    try {
      const updatedQuestion = {
        ...currentQuestion,
        question: {
          ...currentQuestion.question,
          [language]: formData.question,
        },
        options: {
          ...currentQuestion.options,
          [language]: formData.options,
        },
        correct: {
          ...currentQuestion.correct,
          [language]: formData.correct,
        },
        difficulty: formData.difficulty,
        isComplete: true,
      }

      await updateQuestion(categoryId, themeId, levelId, currentQuestion.id, updatedQuestion)

      setQuestions((prev) => {
        const updated = { ...prev }
        if (updated[themeId]?.[levelId]) {
          updated[themeId][levelId] = updated[themeId][levelId].map((q) =>
            q.id === currentQuestion.id ? updatedQuestion : q
          )
        }
        return updated
      })

      setIsEditDialogOpen(false)
      setCurrentQuestion(null)
    } catch (error) {
      console.error("Error updating question:", error)
      alert("Failed to update question. Please try again.")
    }
  }

  const handleDeleteClick = (questionId: string) => {
    setQuestionToDelete(questionId)
    setIsDeleteDialogOpen(true)
  }

  const handleConfirmDelete = async () => {
    if (!questionToDelete) return

    try {
      await deleteQuestion(categoryId, themeId, levelId, questionToDelete)
      setQuestions((prev) => {
        const updated = { ...prev }
        if (updated[themeId]?.[levelId]) {
          updated[themeId][levelId] = updated[themeId][levelId].filter((q) => q.id !== questionToDelete)
        }
        return updated
      })
      setIsDeleteDialogOpen(false)
      setQuestionToDelete(null)
    } catch (error) {
      console.error("Error deleting question:", error)
      alert("Failed to delete question. Please try again.")
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-semibold">
          Questions for {themeTitle} - Level {levelId.replace(/level/i, "")}
        </h2>
        <Button variant="ghost" onClick={() => setSelectedLevel(null)}>
          Back to Levels
        </Button>
      </div>
      {filteredQuestions.length > 0 ? (
        <div className="grid gap-4">
          {filteredQuestions.map((question) => (
            <Card key={question.id}>
              <CardHeader className="flex flex-row items-start justify-between space-y-0">
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <HelpCircle className="h-5 w-5 text-madina-blue" />
                    Question {question.id}
                  </CardTitle>
                  <CardDescription>
                    Difficulty:{" "}
                    <span
                      className={`font-medium ${
                        question.difficulty === "easy"
                          ? "text-green-600"
                          : question.difficulty === "medium"
                          ? "text-amber-600"
                          : "text-red-600"
                      }`}
                    >
                      {question.difficulty}
                    </span>
                    {!question.isComplete && (
                      <span className="ml-2 flex items-center text-yellow-600">
                        <AlertCircle className="h-4 w-4 mr-1" />
                        Translation incomplete
                      </span>
                    )}
                  </CardDescription>
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
                    <DropdownMenuItem onClick={() => handleEditClick(question)}>
                      <Edit className="mr-2 h-4 w-4" />
                      Edit
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      className="text-red-600"
                      onClick={() => handleDeleteClick(question.id)}
                    >
                      <Trash className="mr-2 h-4 w-4" />
                      Delete
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </CardHeader>
              <CardContent>
                <p>{question.question[language] || "Translation missing"}</p>
                <div className="mt-2">
                  <p className="text-sm font-medium">Options:</p>
                  <ul className="list-disc pl-5">
                    {(question.options[language] || []).map((option, index) => (
                      <li key={index} className="text-sm">
                        {option}
                        {option === (question.correct[language] || "") && (
                          <span className="text-green-600 font-medium"> (Correct)</span>
                        )}
                      </li>
                    ))}
                  </ul>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <div className="flex h-40 items-center justify-center rounded-md border border-dashed">
          <p className="text-muted-foreground">No questions found. Add questions to 'questions' subcollection.</p>
        </div>
      )}

      {/* Edit Question Dialog */}
      {currentQuestion && (
        <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
          <DialogContent className="sm:max-w-[600px]">
            <DialogHeader>
              <DialogTitle>Edit Question ({language.toUpperCase()})</DialogTitle>
            </DialogHeader>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label>Question Text ({language.toUpperCase()})</Label>
                <Input
                  placeholder={`Question in ${language.toUpperCase()}`}
                  value={formData.question}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      question: e.target.value,
                    })
                  }
                />
              </div>
              <div className="grid gap-2">
                <Label>Options ({language.toUpperCase()})</Label>
                {formData.options.map((option, index) => (
                  <Input
                    key={`${language}-${index}`}
                    placeholder={`Option ${index + 1}`}
                    value={option}
                    onChange={(e) => {
                      const newOptions = [...formData.options]
                      newOptions[index] = e.target.value
                      setFormData({
                        ...formData,
                        options: newOptions,
                      })
                    }}
                  />
                ))}
              </div>
              <div className="grid gap-2">
                <Label>Correct Answer ({language.toUpperCase()})</Label>
                <Input
                  placeholder={`Correct answer in ${language.toUpperCase()}`}
                  value={formData.correct}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      correct: e.target.value,
                    })
                  }
                />
              </div>
              <div className="grid gap-2">
                <Label>Difficulty</Label>
                <Select
                  value={formData.difficulty}
                  onValueChange={(value) =>
                    setFormData({ ...formData, difficulty: value })
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
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setIsEditDialogOpen(false)}>
                Cancel
              </Button>
              <Button onClick={handleSave}>Save</Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Deletion</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete this question? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDeleteDialogOpen(false)}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleConfirmDelete}>
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}