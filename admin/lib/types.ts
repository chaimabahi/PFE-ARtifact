import { Timestamp } from "firebase/firestore"

export type Category = {
  id: string
  name: string
}

export type Theme = {
  id: string
  title: string
  image: string
}

export type Level = {
  id: string
}

export type Question = {
  id: string
  question: { ar: string; en: string; fr: string }
  correct: { ar: string; en: string; fr: string }
  options: { ar: string[]; en: string[]; fr: string[] }
  createdAt: Timestamp 
}