"use client"

import { Bell, Search } from "lucide-react"
import { ThemeToggle } from "@/components/theme-toggle"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

export function Header() {
  return (
    <header className="sticky top-0 z-30 flex h-16 items-center gap-4 border-b bg-background px-4 md:px-6">
  
      <div className="flex flex-1 items-center justify-end gap-4 md:justify-end">

        <ThemeToggle />
      </div>
    </header>
  )
}

