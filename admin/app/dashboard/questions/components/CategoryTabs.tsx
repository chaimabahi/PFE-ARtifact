import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import ThemeList from "./ThemeList"
import LevelList from "./LevelList"
import QuestionList from "./QuestionList"
import { Category, Theme, Level, Question } from "../../../../lib/types"

interface CategoryTabsProps {
  categories: Category[]
  activeCategory: string
  setActiveCategory: (value: string) => void
  themes: Record<string, Theme[]>
  levels: Record<string, Level[]>
  questions: Record<string, Record<string, Question[]>>
  searchTerm: string
  selectedTheme: string | null
  setSelectedTheme: (value: string | null) => void
  selectedLevel: string | null
  setSelectedLevel: (value: string | null) => void
  language: "ar" | "en" | "fr"
  loading: boolean
  setQuestions: React.Dispatch<React.SetStateAction<Record<string, Record<string, Question[]>>>>
}

export default function CategoryTabs({
  categories,
  activeCategory,
  setActiveCategory,
  themes,
  levels,
  questions,
  searchTerm,
  selectedTheme,
  setSelectedTheme,
  selectedLevel,
  setSelectedLevel,
  language,
  loading,
  setQuestions,
}: CategoryTabsProps) {
  return (
    <>
      {categories.length === 0 && !loading ? (
        <div className="flex h-40 items-center justify-center rounded-md border border-dashed">
          <p className="text-muted-foreground">No categories found. Please add categories to 'quizze' collection.</p>
        </div>
      ) : (
        <Tabs value={activeCategory} onValueChange={setActiveCategory}>
          <TabsList className="mb-4 flex h-auto flex-wrap">
            {categories.map((category) => (
              <TabsTrigger key={category.id} value={category.id} className="h-9">
                {category.name}
              </TabsTrigger>
            ))}
          </TabsList>

          {categories.map((category) => (
            <TabsContent key={category.id} value={category.id} className="space-y-4">
              {!selectedTheme ? (
                <ThemeList
                  themes={themes[category.id] || []}
                  searchTerm={searchTerm}
                  setSelectedTheme={setSelectedTheme}
                  categoryId={category.id}
                  language={language} // Pass language prop
                />
              ) : !selectedLevel ? (
                <LevelList
                  levels={levels[selectedTheme] || []}
                  themeTitle={themes[category.id]?.find((t) => t.id === selectedTheme)?.title[language] || "Untitled"}
                  setSelectedLevel={setSelectedLevel}
                  setSelectedTheme={setSelectedTheme}
                  loading={loading}
                />
              ) : (
                <QuestionList
                  questions={questions[selectedTheme]?.[selectedLevel] || []}
                  searchTerm={searchTerm}
                  language={language}
                  categoryId={category.id}
                  themeId={selectedTheme}
                  levelId={selectedLevel}
                  themeTitle={themes[category.id]?.find((t) => t.id === selectedTheme)?.title[language] || "Untitled"}
                  setSelectedLevel={setSelectedLevel}
                  setQuestions={setQuestions}
                />
              )}
            </TabsContent>
          ))}
        </Tabs>
      )}
    </>
  )
}