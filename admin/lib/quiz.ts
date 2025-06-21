import { db } from "@/lib/firebase"
import { collection, getDocs, deleteDoc, doc, setDoc } from "firebase/firestore"
import { Timestamp } from "firebase/firestore"
import { Category, Theme, Level, Question } from "./types"

export async function fetchCategoriesThemesAndLevels() {
  const categoriesData: Category[] = []
  const themesData: Record<string, Theme[]> = {}
  const levelsData: Record<string, Level[]> = {}

  try {
    const categoriesCollection = collection(db, "quizze")
    const categoriesSnapshot = await getDocs(categoriesCollection)

    for (const categoryDoc of categoriesSnapshot.docs) {
      const categoryId = categoryDoc.id
      const categoryName = categoryDoc.data().name || categoryId
      categoriesData.push({ id: categoryId, name: categoryName })

      const possibleThemePaths = [`quizze/${categoryId}/themes`, `quizze/${categoryId}/Themes`]
      let themesSnapshot = null
      for (const path of possibleThemePaths) {
        const themesCollection = collection(db, path)
        themesSnapshot = await getDocs(themesCollection)
        if (!themesSnapshot.empty) break
      }

      if (themesSnapshot && !themesSnapshot.empty) {
        themesData[categoryId] = themesSnapshot.docs.map((themeDoc) => {
          const themeData = themeDoc.data()
          return {
            id: themeDoc.id,
            title: themeData.title || themeData.Title || "Untitled Theme",
            image: themeData.image || themeData.Image || "/placeholder.svg?height=200&width=300",
          }
        })

        for (const theme of themesData[categoryId]) {
          const possibleLevelPaths = [
            `quizze/${categoryId}/themes/${theme.id}/levels`,
            `quizze/${categoryId}/themes/${theme.id}/Levels`,
            `quizze/${categoryId}/Themes/${theme.id}/levels`,
            `quizze/${categoryId}/Themes/${theme.id}/Levels`,
          ]
          let levelsSnapshot = null
          for (const path of possibleLevelPaths) {
            const levelsCollection = collection(db, path)
            levelsSnapshot = await getDocs(levelsCollection)
            if (!levelsSnapshot.empty) break
          }

          levelsData[theme.id] = levelsSnapshot && !levelsSnapshot.empty
            ? levelsSnapshot.docs.map((levelDoc) => ({ id: levelDoc.id }))
            : []
        }
      } else {
        themesData[categoryId] = []
      }
    }

    if (categoriesData.length === 0) {
      themesData["default"] = []
    }

    return { categoriesData, themesData, levelsData }
  } catch (error) {
    console.error("Error fetching categories, themes, and levels:", error)
    throw error
  }
}

export async function fetchQuestions(themes: Record<string, Theme[]>, levels: Record<string, Level[]>) {
  const questionsData: Record<string, Record<string, Question[]>> = {}

  Object.keys(themes).forEach((categoryId) => {
    themes[categoryId].forEach((theme) => {
      questionsData[theme.id] = {}
      levels[theme.id]?.forEach((level) => {
        questionsData[theme.id][level.id] = []
      })
    })
  })

  for (const categoryId of Object.keys(themes)) {
    for (const theme of themes[categoryId]) {
      for (const level of levels[theme.id] || []) {
        const possibleQuestionPaths = [
          `quizze/${categoryId}/themes/${theme.id}/levels/${level.id}/questions`,
          `quizze/${categoryId}/themes/${theme.id}/levels/${level.id}/Questions`,
          `quizze/${categoryId}/Themes/${theme.id}/levels/${level.id}/questions`,
          `quizze/${categoryId}/Themes/${theme.id}/levels/${level.id}/Questions`,
          `quizze/${categoryId}/themes/${theme.id}/Levels/${level.id}/questions`,
          `quizze/${categoryId}/themes/${theme.id}/Levels/${level.id}/Questions`,
          `quizze/${categoryId}/Themes/${theme.id}/Levels/${level.id}/questions`,
          `quizze/${categoryId}/Themes/${theme.id}/Levels/${level.id}/Questions`,
        ]
        let questionsSnapshot = null
        for (const path of possibleQuestionPaths) {
          const questionsCollection = collection(db, path)
          questionsSnapshot = await getDocs(questionsCollection)
          if (!questionsSnapshot.empty) break
        }

        if (questionsSnapshot && !questionsSnapshot.empty) {
          questionsData[theme.id][level.id] = questionsSnapshot.docs.map((doc) => {
            const data = doc.data()
            const question: Question = {
              id: doc.id,
              question: {
                ar: data.question?.ar || data.Question?.ar || "",
                en: data.question?.en || data.Question?.en || "No question text",
                fr: data.question?.fr || data.Question?.fr || "",
              },
              correct: {
                ar: data.correct?.ar || data.Correct?.ar || "",
                en: data.correct?.en || data.Correct?.en || "",
                fr: data.correct?.fr || data.Correct?.fr || "",
              },
              options: {
                ar: data.options?.ar || data.Options?.ar || [],
                en: data.options?.en || data.Options?.en || [],
                fr: data.options?.fr || data.Options?.fr || [],
              },
              difficulty: data.difficulty || data.Difficulty || "medium",
              isComplete: false,
              createdAt: data.createdAt || Timestamp.fromDate(new Date(0)),
            }
            question.isComplete = !!(
              question.question.ar &&
              question.question.en &&
              question.question.fr &&
              question.correct.ar &&
              question.correct.en &&
              question.correct.fr &&
              question.options.ar.length > 0 &&
              question.options.en.length > 0 &&
              question.options.fr.length > 0
            )
            return question
          })
        }
      }
    }
  }

  return questionsData
}

export async function deleteQuestion(categoryId: string, themeId: string, levelId: string, questionId: string) {
  const path = `quizze/${categoryId}/themes/${themeId}/levels/${levelId}/questions`
  await deleteDoc(doc(db, path, questionId))
}

export async function addQuestion(
  categoryId: string,
  themeId: string,
  levelId: string,
  questionData: Omit<Question, "id" | "isComplete" | "createdAt">,
  questionId?: string
) {
  const path = `quizze/${categoryId}/themes/${themeId}/levels/${levelId}/questions`
  const questionRef = questionId ? doc(db, path, questionId) : doc(collection(db, path))
  const question: Question = {
    ...questionData,
    id: questionRef.id,
    isComplete: !!(
      questionData.question.ar &&
      questionData.question.en &&
      questionData.question.fr &&
      questionData.correct.ar &&
      questionData.correct.en &&
      questionData.correct.fr &&
      questionData.options.ar.length > 0 &&
      questionData.options.en.length > 0 &&
      questionData.options.fr.length > 0
    ),
    createdAt: Timestamp.now(),
  }
  await setDoc(questionRef, question)
  return question
}

export async function updateQuestion(
  categoryId: string,
  themeId: string,
  levelId: string,
  questionId: string,
  updatedData: Partial<Question>
) {
  try {
    const path = `quizze/${categoryId}/themes/${themeId}/levels/${levelId}/questions`
    const questionRef = doc(db, path, questionId)

    const updatedQuestion: Partial<Question> = {
      ...updatedData,
      createdAt: Timestamp.now(),
    }

    updatedQuestion.isComplete = !!(
      updatedQuestion.question?.ar &&
      updatedQuestion.question?.en &&
      updatedQuestion.question?.fr &&
      updatedQuestion.correct?.ar &&
      updatedQuestion.correct?.en &&
      updatedQuestion.correct?.fr &&
      updatedQuestion.options?.ar?.length > 0 &&
      updatedQuestion.options?.en?.length > 0 &&
      updatedQuestion.options?.fr?.length > 0
    )

    await setDoc(questionRef, updatedQuestion, { merge: true })
  } catch (error) {
    console.error("Error updating question:", error)
    throw error
  }
}

export async function addTheme(categoryId: string, themeData: Omit<Theme, "id">) {
  try {
    const path = `quizze/${categoryId}/themes`
    const themeRef = doc(collection(db, path))
    const theme: Theme = {
      ...themeData,
      id: themeRef.id,
    }
    await setDoc(themeRef, theme)
    return theme
  } catch (error) {
    console.error("Error adding theme:", error)
    throw error
  }
}

export async function addCategory(categoryData: Omit<Category, "id">) {
  try {
    const path = `quizze`
    const categoryRef = doc(collection(db, path))
    const category: Category = {
      ...categoryData,
      id: categoryRef.id,
    }
    await setDoc(categoryRef, category)
    return category
  } catch (error) {
    console.error("Error adding category:", error)
    throw error
  }
}

export async function addLevel(categoryId: string, themeId: string, levelData: Omit<Level, "id">) {
  try {
    const path = `quizze/${categoryId}/themes/${themeId}/levels`
    const levelRef = doc(db, path, levelData.id)
    const level: Level = {
      ...levelData,
      id: levelRef.id,
    }
    await setDoc(levelRef, level)
    return level
  } catch (error) {
    console.error("Error adding level:", error)
    throw error
  }
}