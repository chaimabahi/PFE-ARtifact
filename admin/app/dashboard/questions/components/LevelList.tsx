import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Level } from "../../../../lib/types"

interface LevelListProps {
  levels: Level[]
  themeTitle: string
  setSelectedLevel: (value: string | null) => void
  setSelectedTheme: (value: string | null) => void
  loading: boolean
}

export default function LevelList({
  levels,
  themeTitle,
  setSelectedLevel,
  setSelectedTheme,
  loading,
}: LevelListProps) {
  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-semibold">Levels for {themeTitle}</h2>
        <Button variant="ghost" onClick={() => setSelectedTheme(null)}>
          Back to Themes
        </Button>
      </div>
      {loading ? (
        <div className="flex h-40 items-center justify-center">
          <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-madina-blue"></div>
        </div>
      ) : levels.length > 0 ? (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {levels.map((level) => (
            <Card key={level.id} className="cursor-pointer" onClick={() => setSelectedLevel(level.id)}>
              <CardHeader>
                <CardTitle>Level {level.id.replace(/level/i, "")}</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground">6 Questions</p>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <div className="flex h-40 items-center justify-center rounded-md border border-dashed">
          <p className="text-muted-foreground">No levels found for this theme. Add levels to 'levels' subcollection.</p>
        </div>
      )}
    </div>
  )
}