import { initializeApp, getApps, getApp } from "firebase/app"
import { getFirestore } from "firebase/firestore"
import { getAuth } from "firebase/auth"
import { getStorage } from "firebase/storage"

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyB8SveKZiQ1U9c9ZI_jW5NZ6WHQBSp3DDo",
  authDomain: "artefacts-615ee.firebaseapp.com",
  projectId: "artefacts-615ee",
  storageBucket: "artefacts-615ee.firebasestorage.app",
  messagingSenderId: "737285476811",
  appId: "1:737285476811:web:6243389dd5b0a51b73264e"
};

// Initialize Firebase
const app = !getApps().length ? initializeApp(firebaseConfig) : getApp()
const db = getFirestore(app)
const auth = getAuth(app)
const storage = getStorage(app)

export { app, db, auth, storage }

