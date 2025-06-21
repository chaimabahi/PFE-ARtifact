"use client"

import { Button } from "@/components/ui/button"
import { signOutAdmin } from "@/lib/auth"
import { useRouter } from "next/navigation"
import { LogOut } from "lucide-react"

export function LogoutButton() {
  const router = useRouter()

  const handleLogout = async () => {
    try {
      await signOutAdmin()
      router.replace("/login")
    } catch (error) {
      console.error("Logout failed:", error)
    }
  }

  return (
    <Button variant="outline" onClick={handleLogout} className="flex items-center gap-2">
      <LogOut className="h-4 w-4" />
      Logout
    </Button>
  )
}
