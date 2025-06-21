"use client"

import { useEffect, useState } from "react"
import type { User } from "firebase/auth"
import { auth } from "../lib/firebase"
import { getCurrentAdminUser, type AdminUser } from "@/lib/auth"

export function useAuth() {
  const [user, setUser] = useState<AdminUser | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged(async (firebaseUser: User | null) => {
      if (firebaseUser) {
        try {
          const adminUser = await getCurrentAdminUser()
          setUser(adminUser)
        } catch (error) {
          setUser(null)
        }
      } else {
        setUser(null)
      }
      setLoading(false)
    })

    return () => unsubscribe()
  }, [])

  return { user, loading }
}
