import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import Image from "next/image"
import { Theme } from "../../../../lib/types"

interface ThemeListProps {
  themes: Theme[]
  searchTerm: string
  setSelectedTheme: (value: string | null) => void
  categoryId: string
  language: "ar" | "en" | "fr"
}

export default function ThemeList({ themes, searchTerm, setSelectedTheme, categoryId, language }: ThemeListProps) {
  const filteredThemes = themes.filter((theme) =>
    (theme.title[language] || "").toLowerCase().includes(searchTerm.toLowerCase())
  )

  return filteredThemes.length > 0 ? (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {filteredThemes.map((theme) => (
        <Card key={theme.id} className="cursor-pointer" onClick={() => setSelectedTheme(theme.id)}>
          <CardHeader>
            <CardTitle>{theme.title[language] || "Untitled"}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="relative h-40 w-full">
              <Image src={theme.image} alt={theme.title[language] || "Untitled"} fill className="object-cover rounded-md" />
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  ) : (
    <div className="flex h-40 items-center justify-center rounded-md border border-dashed">
      <p className="text-muted-foreground">No themes found for this category. Add themes to 'quizze/{categoryId}/themes'.</p>
    </div>
  )
}