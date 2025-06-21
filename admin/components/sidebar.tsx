"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import Image from "next/image"
import { usePathname } from "next/navigation"
import { BarChart3, Users, FileText, HelpCircle, Settings, Menu, X, Home, PartyPopper ,CircleHelp  } from "lucide-react"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { getCurrentAdminUser, AdminUser } from "../lib/auth" // Import the auth function and type

const routes = [
  {
    label: "Dashboard",
    icon: Home,
    href: "/dashboard",
    color: "text-madina-blue",
  },
  {
    label: "Users",
    icon: Users,
    href: "/dashboard/users",
    color: "text-madina-blue",
  },
  {
    label: "Blogs",
    icon: FileText,
    href: "/dashboard/blogs",
    color: "text-madina-blue",
  },
  {
    label: "Quiz",
    icon: HelpCircle,
    href: "/dashboard/questions",
    color: "text-madina-blue",
  },
  {
    label: "Events",
    icon: PartyPopper,
    href: "/dashboard/events",
    color: "text-madina-blue",
  },
   {
    label: "Support",
    icon: CircleHelp ,
    href: "/dashboard/support",
    color: "text-madina-blue",
  },
]

export function Sidebar() {
  const pathname = usePathname()
  const [isOpen, setIsOpen] = useState(false)
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null) // State for admin user

  // Fetch current admin user on component mount
  useEffect(() => {
    async function fetchAdminUser() {
      const user = await getCurrentAdminUser()
      setAdminUser(user)
    }
    fetchAdminUser()
  }, [])

  return (
    <>
      <Button
        variant="outline"
        size="icon"
        className="fixed right-4 top-4 z-50 md:hidden"
        onClick={() => setIsOpen(!isOpen)}
      >
        {isOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
      </Button>
      <div
        className={cn(
          "fixed inset-y-0 left-0 z-40 flex w-72 flex-col bg-white shadow-lg transition-transform duration-300 dark:bg-gray-900 md:static md:translate-x-0",
          isOpen ? "translate-x-0" : "-translate-x-full",
        )}
      >
        <div className="flex h-20 items-center border-b px-6">
          <Link href="/dashboard" className="flex items-center gap-2">
            <Image
              src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/logo-removebg-preview-e0pKMwZzW8vSifGP6POxdluXycxuq8.png"
              alt="GOLDEN MADINA Logo"
              width={40}
              height={40}
              className="rounded-md"
            />
            <span className="text-xl font-bold text-madina-blue dark:text-white">GOLDEN MADINA</span>
          </Link>
        </div>
        <div className="flex-1 overflow-auto py-6">
          <nav className="grid gap-2 px-4">
            {routes.map((route) => (
              <Link
                key={route.href}
                href={route.href}
                className={cn(
                  "flex items-center gap-3 rounded-lg px-3 py-2 text-gray-700 transition-all hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800",
                  pathname === route.href && "bg-gray-100 dark:bg-gray-800",
                )}
              >
                <route.icon className={cn("h-5 w-5", route.color)} />
                <span>{route.label}</span>
              </Link>
            ))}
          </nav>
        </div>
        <div className="border-t p-4">
          <div className="flex items-center gap-3 rounded-lg px-3 py-2">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-madina-blue text-white">
              <span className="text-sm font-medium">GM</span>
            </div>
            <div>
              <p className="text-sm font-medium">Admin account</p>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                {adminUser?.email || "Loading..."}
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}