import { signInWithEmailAndPassword, signOut, type User } from "firebase/auth"
import { doc, getDoc } from "firebase/firestore"
import { auth, db } from "./firebase"

export interface AdminUser {
  uid: string
  email: string
  role: string
  name?: string
  createdAt?: any
}

export async function signInAdmin(email: string, password: string): Promise<AdminUser> {
  try {
    // Sign in with Firebase Auth
    const userCredential = await signInWithEmailAndPassword(auth, email, password)
    const user = userCredential.user

    // Check if user exists in Firestore users collection
    const userDocRef = doc(db, "users", user.uid)
    const userDoc = await getDoc(userDocRef)

    if (!userDoc.exists()) {
      await signOut(auth)
      throw new Error("User not found in database")
    }

    const userData = userDoc.data()

    // Check if user has admin role
    if (userData.role !== "admin") {
      await signOut(auth)
      throw new Error("Access denied. Admin privileges required.")
    }

    return {
      uid: user.uid,
      email: user.email!,
      role: userData.role,
      name: userData.name,
      createdAt: userData.createdAt,
    }
  } catch (error: any) {
    throw new Error(error.message || "Authentication failed")
  }
}

export async function signOutAdmin(): Promise<void> {
  try {
    await signOut(auth)
  } catch (error: any) {
    throw new Error(error.message || "Sign out failed")
  }
}

export async function getCurrentAdminUser(): Promise<AdminUser | null> {
  return new Promise((resolve) => {
    const unsubscribe = auth.onAuthStateChanged(async (user: User | null) => {
      unsubscribe()

      if (!user) {
        resolve(null)
        return
      }

      try {
        const userDocRef = doc(db, "users", user.uid)
        const userDoc = await getDoc(userDocRef)

        if (!userDoc.exists()) {
          resolve(null)
          return
        }

        const userData = userDoc.data()

        if (userData.role !== "admin") {
          resolve(null)
          return
        }

        resolve({
          uid: user.uid,
          email: user.email!,
          role: userData.role,
          name: userData.name,
          createdAt: userData.createdAt,
        })
      } catch (error) {
        resolve(null)
      }
    })
  })
}
