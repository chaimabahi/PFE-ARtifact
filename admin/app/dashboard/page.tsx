"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { UsersIcon, FileText, HelpCircle, TrendingUp, Activity } from "lucide-react"
import { db } from "@/lib/firebase"
import { collection, getDocs, query, where, orderBy, limit, type Timestamp } from "firebase/firestore"
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, LineElement, PointElement, Title, Tooltip, Legend } from "chart.js"
import { Bar, Line } from "react-chartjs-2"
import { useAuth } from "@/hooks/use-auth"
import { useRouter } from "next/navigation"
import { LogoutButton } from "@/components/logout-button"

// Register Chart.js components
ChartJS.register(CategoryScale, LinearScale, BarElement, LineElement, PointElement, Title, Tooltip, Legend)

// Types for our data
type DashboardStats = {
  totalUsers: number
  totalBlogPosts: number
  totalQuestions: number
  activeUsers: number
  userGrowth: number
  blogGrowth: number
  activeUserGrowth: number
  recentActivity: RecentActivity[]
  monthlyUserData: number[]
  monthlyBlogData: number[]
  eventAgeData: { eventTitle: string; avgAge: number; participantCount: number }[]
}

type RecentActivity = {
  id: string
  type: "user" | "blog" | "question"
  title: string
  timestamp: Timestamp | string | null
}

export default function DashboardPage() {
  const { user, loading: authLoading } = useAuth()
  const router = useRouter()

  const [stats, setStats] = useState<DashboardStats>({
    totalUsers: 0,
    totalBlogPosts: 0,
    totalQuestions: 0,
    activeUsers: 0,
    userGrowth: 0,
    blogGrowth: 0,
    activeUserGrowth: 0,
    recentActivity: [],
    monthlyUserData: Array(12).fill(0),
    monthlyBlogData: Array(12).fill(0),
    eventAgeData: [],
  })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Helper function to convert createdAt to Date
  const convertToDate = (timestamp: Timestamp | string | Date | null): Date | null => {
    if (!timestamp) return null
    if ((timestamp as Timestamp).toDate && typeof (timestamp as Timestamp).toDate === "function") {
      return (timestamp as Timestamp).toDate()
    } else if (typeof timestamp === "string") {
      const parsedDate = new Date(timestamp)
      return isNaN(parsedDate.getTime()) ? null : parsedDate
    } else if (timestamp instanceof Date) {
      return timestamp
    }
    return null
  }

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !user) {
      router.replace("/login")
    }
  }, [user, authLoading, router])

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true)
        setError(null)

        const currentYear = new Date().getFullYear()
        const monthlyUserData = Array(12).fill(0)
        const monthlyBlogData = Array(12).fill(0)

        // Fetch all users
        const usersSnapshot = await getDocs(collection(db, "users"))
        const totalUsers = usersSnapshot.size
        console.log(`Found ${totalUsers} users`)
        const allUsers = usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))

        // Log user details
        allUsers.forEach(user => {
          console.log(`User ${user.id}: age=${user.age}, participantIds=${JSON.stringify(user.participantIds || [])}`)
          const createdDate = convertToDate(user.createdAt)
          if (createdDate && createdDate.getFullYear() === currentYear) {
            monthlyUserData[createdDate.getMonth()]++
          }
        })

        // Check for users with event participation
        const usersWithEvents = allUsers.filter(user => user.participantIds?.length > 0)
        if (usersWithEvents.length) {
          console.log(`${usersWithEvents.length} users have participated in events:`)
          usersWithEvents.forEach(user => {
            console.log(`User ${user.id} (${user.email || user.username || "Anonymous"}):`, 
              user.participantIds.map((pid: any) => `Event ${pid.eventId} (${pid.title})`))
          })
        } else {
          console.log("No users have participated in any events.")
        }

        // Fetch blog posts
        const blogsSnapshot = await getDocs(collection(db, "blogs"))
        const totalBlogPosts = blogsSnapshot.size
        blogsSnapshot.forEach(doc => {
          const blogData = doc.data()
          const createdDate = convertToDate(blogData.createdAt)
          if (createdDate && createdDate.getFullYear() === currentYear) {
            monthlyBlogData[createdDate.getMonth()]++
          }
        })

        // Calculate active users (last 30 days)
        const thirtyDaysAgo = new Date()
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
        const activeUsersQuery = query(collection(db, "users"), where("lastLogin", ">=", thirtyDaysAgo))
        const activeUsersSnapshot = await getDocs(activeUsersQuery)
        const activeUsers = activeUsersSnapshot.size

        // Calculate growth percentages
        const lastMonthUsers = monthlyUserData[11] + monthlyUserData[10]
        const prevMonthUsers = monthlyUserData[9] + monthlyUserData[8]
        const userGrowth = prevMonthUsers > 0 ? ((lastMonthUsers - prevMonthUsers) / prevMonthUsers) * 100 : 0

        const lastMonthBlogs = monthlyBlogData[11] + monthlyBlogData[10]
        const prevMonthBlogs = monthlyBlogData[9] + monthlyBlogData[8]
        const blogGrowth = prevMonthBlogs > 0 ? ((lastMonthBlogs - prevMonthBlogs) / prevMonthBlogs) * 100 : 0

        const lastWeekActive = activeUsers
        const activeUserGrowth = lastWeekActive > 0 ? (lastWeekActive / totalUsers) * 100 : 0

        // Fetch recent activity
        const recentActivity: RecentActivity[] = []

        // Recent users
        const recentUsersQuery = query(collection(db, "users"), orderBy("createdAt", "desc"), limit(5))
        const recentUsersSnapshot = await getDocs(recentUsersQuery)
        recentUsersSnapshot.forEach(doc => {
          const userData = doc.data()
          if (userData.createdAt) {
            recentActivity.push({
              id: doc.id,
              type: "user",
              title: `New user: ${userData.name || userData.email || "Anonymous"}`,
              timestamp: userData.createdAt,
            })
          }
        })

        // Recent blog posts
        const recentBlogsQuery = query(collection(db, "blogs"), orderBy("createdAt", "desc"), limit(5))
        const recentBlogsSnapshot = await getDocs(recentBlogsQuery)
        recentBlogsSnapshot.forEach(doc => {
          const blogData = doc.data()
          if (blogData.createdAt) {
            recentActivity.push({
              id: doc.id,
              type: "blog",
              title: `New blog: ${blogData.title?.en || "Untitled"}`,
              timestamp: blogData.createdAt,
            })
          }
        })

        // Sort and limit recent activity
        recentActivity.sort((a, b) => {
          const aTime = convertToDate(a.timestamp)?.getTime() || 0
          const bTime = convertToDate(b.timestamp)?.getTime() || 0
          return bTime - aTime
        })
        const limitedActivity = recentActivity.slice(0, 5)

        // Build event list from participantIds
        const eventAgeData: { eventTitle: string; avgAge: number; participantCount: number }[] = []
        const uniqueEventsMap = new Map<string, string>()
        allUsers.forEach(user => {
          if (user.participantIds && Array.isArray(user.participantIds)) {
            user.participantIds.forEach((pid: any) => {
              if (pid.eventId && pid.title) {
                uniqueEventsMap.set(pid.eventId, pid.title)
              }
            })
          }
        })

        console.log(`Found ${uniqueEventsMap.size} unique events from participantIds:`, 
          Array.from(uniqueEventsMap.entries()).map(([id, title]) => ({ eventId: id, title })))

        // Calculate average age for each event
        for (const [eventId, eventTitle] of uniqueEventsMap) {
          const participants = allUsers.filter(user => 
            user.participantIds?.some((pid: any) => pid.eventId === eventId)
          )
          console.log(`Event ${eventId} (${eventTitle}): Found ${participants.length} participants`)

          let totalAge = 0
          let userCount = 0
          participants.forEach(user => {
            console.log(`Participant ${user.id}: age=${user.age}, participantIds=${JSON.stringify(user.participantIds)}`)
            if (user.age && typeof user.age === "number" && !isNaN(user.age)) {
              totalAge += user.age
              userCount++
            } else {
              console.log(`Skipping user ${user.id}: Invalid or missing age (age=${user.age})`)
            }
          })

          if (userCount >= 2) {
            const avgAge = userCount > 0 ? totalAge / userCount : 0
            eventAgeData.push({
              eventTitle,
              avgAge: Number(avgAge.toFixed(1)),
              participantCount: userCount,
            })
            console.log(`Event ${eventId} (${eventTitle}): avgAge=${avgAge.toFixed(1)}, participantCount=${userCount}`)
          } else {
            console.log(`Event ${eventId} (${eventTitle}): Skipped (only ${userCount} participants)`)
          }
        }

        // Sort events by title
        eventAgeData.sort((a, b) => a.eventTitle.localeCompare(b.eventTitle))
        console.log(`Final eventAgeData: ${JSON.stringify(eventAgeData)}`)

        setStats({
          totalUsers,
          totalBlogPosts,
          totalQuestions: 0,
          activeUsers,
          userGrowth: Number(userGrowth.toFixed(1)),
          blogGrowth: Number(blogGrowth.toFixed(1)),
          activeUserGrowth: Number(activeUserGrowth.toFixed(1)),
          recentActivity: limitedActivity,
          monthlyUserData,
          monthlyBlogData,
          eventAgeData,
        })
      } catch (err) {
        console.error("Error fetching dashboard data:", err)
        setError("Failed to load dashboard data. Please check Firestore permissions or data structure.")
      } finally {
        setLoading(false)
      }
    }

    if (user) {
      fetchDashboardData()
    }
  }, [user])

  // Chart data configuration
  const userChartData = {
    labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    datasets: [
      {
        label: "New Users",
        data: stats.monthlyUserData,
        backgroundColor: "rgba(59, 130, 246, 0.5)",
        borderColor: "rgb(59, 130, 246)",
        borderWidth: 1,
      },
    ],
  }

  const blogChartData = {
    labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    datasets: [
      {
        label: "New Blog Posts",
        data: stats.monthlyBlogData,
        backgroundColor: "rgba(16, 185, 129, 0.5)",
        borderColor: "rgb(16, 185, 129)",
        borderWidth: 1,
      },
    ],
  }

  const eventAgeChartData = {
    // Duplicate the label and data to create a minimal line segment
    labels: stats.eventAgeData.length > 0 
      ? [...stats.eventAgeData.map((event) => event.eventTitle), stats.eventAgeData[0].eventTitle + " (end)"]
      : [],
    datasets: [
      {
        label: "Average Age of Participants",
        data: stats.eventAgeData.length > 0 
          ? [...stats.eventAgeData.map((event) => event.avgAge), stats.eventAgeData[0].avgAge]
          : [],
        fill: false,
        borderColor: "rgb(75, 192, 192)",
        backgroundColor: "rgba(75, 192, 192, 0.5)",
        borderWidth: 3, // Thicker line for visibility
        tension: 0.4, // Smooth curve
        pointRadius: 6, // Larger points
        pointHoverRadius: 8,
        showLine: true, // Ensure line is drawn
      },
    ],
  }

  // Chart options
  const userChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: "top" as const,
      },
      tooltip: {
        callbacks: {
          label: (context: any) => {
            const value = context.parsed.y
            return `${context.dataset.label}: ${value} users`
          },
        },
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        title: {
          display: true,
          text: "Number of Users",
        },
      },
      x: {
        title: {
          display: true,
          text: "Months",
        },
      },
    },
  }

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: "top" as const,
      },
      tooltip: {
        callbacks: {
          label: (context: any) => {
            const index = context.dataIndex
            const datasetLabel = context.dataset.label || ""
            if (datasetLabel === "New Blog Posts") {
              return `${datasetLabel}: ${context.parsed.y} posts`
            } else if (datasetLabel === "Average Age of Participants") {
              // Use the original event data (avoid the duplicated "end" point)
              const eventIndex = Math.min(index, stats.eventAgeData.length - 1)
              const event = stats.eventAgeData[eventIndex]
              return `${datasetLabel}: ${event.avgAge} (${event.participantCount} participants)`
            }
            return `${datasetLabel}: ${context.parsed.y}`
          },
        },
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        title: {
          display: true,
          text: (context: any) => {
            const datasetLabel = context.chart.data.datasets[0]?.label || ""
            if (datasetLabel === "New Blog Posts") return "Number of Blog Posts"
            return "Average Age"
          },
        },
      },
      x: {
        title: {
          display: true,
          text: (context: any) => {
            const datasetLabel = context.chart.data.datasets[0]?.label || ""
            if (datasetLabel === "New Blog Posts") return "Months"
            return "Events"
          },
        },
      },
    },
  }

  // Helper function to format time ago
  const getTimeAgo = (timestamp: Timestamp | string | Date | null): string => {
    if (!timestamp) return "Unknown time"
    const date = convertToDate(timestamp)
    if (!date) return "Unknown time"
    const now = new Date()
    const timeMs = date.getTime()
    const diffMs = now.getTime() - timeMs
    const diffMins = Math.floor(diffMs / (1000 * 60))
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

    if (diffMins < 60) return `${diffMins} minute${diffMins !== 1 ? "s" : ""} ago`
    if (diffHours < 24) return `${diffHours} hour${diffHours !== 1 ? "s" : ""} ago`
    return `${diffDays} day${diffDays !== 1 ? "s" : ""} ago`
  }

  // Helper function to get icon for activity type
  const getActivityIcon = (type: string) => {
    switch (type) {
      case "user":
        return <UsersIcon className="h-4 w-4 text-primary" />
      case "blog":
        return <FileText className="h-4 w-4 text-primary" />
      case "question":
        return <HelpCircle className="h-4 w-4 text-primary" />
      default:
        return <Activity className="h-4 w-4 text-primary" />
    }
  }

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (!user) {
    return null
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Header with logout button */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-muted-foreground">
            Welcome to the GOLDEN MADINA admin dashboard
          </p>
        </div>
        <LogoutButton />
      </div>

      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative" role="alert">
          <strong className="font-bold">Error: </strong>
          <span className="block sm:inline">{error}</span>
        </div>
      )}

      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="analytics">Analytics</TabsTrigger>
        </TabsList>
        <TabsContent value="overview" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Users</CardTitle>
                <UsersIcon className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                {loading ? (
                  <div className="h-8 w-24 animate-pulse rounded bg-muted"></div>
                ) : (
                  <>
                    <div className="text-2xl font-bold">{stats.totalUsers.toLocaleString()}</div>
                    <p className="text-xs text-muted-foreground">
                      {stats.userGrowth >= 0 ? "+" : ""}
                      {stats.userGrowth}% from last month
                    </p>
                  </>
                )}
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Blog Posts</CardTitle>
                <FileText className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                {loading ? (
                  <div className="h-8 w-24 animate-pulse rounded bg-muted"></div>
                ) : (
                  <>
                    <div className="text-2xl font-bold">{stats.totalBlogPosts.toLocaleString()}</div>
                    <p className="text-xs text-muted-foreground">
                      {stats.blogGrowth >= 0 ? "+" : ""}
                      {stats.blogGrowth}% from last month
                    </p>
                  </>
                )}
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Questions</CardTitle>
                <HelpCircle className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                {loading ? (
                  <div className="h-8 w-24 animate-pulse rounded bg-muted"></div>
                ) : (
                  <>
                    <div className="text-2xl font-bold">{stats.totalQuestions.toLocaleString()}</div>
                    <p className="text-xs text-muted-foreground">Across 0 themes</p>
                  </>
                )}
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Active Users</CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                {loading ? (
                  <div className="h-8 w-24 animate-pulse rounded bg-muted"></div>
                ) : (
                  <>
                    <div className="text-2xl font-bold">{stats.activeUsers.toLocaleString()}</div>
                    <p className="text-xs text-muted-foreground">
                      {stats.activeUserGrowth >= 0 ? "+" : ""}
                      {stats.activeUserGrowth}% from last week
                    </p>
                  </>
                )}
              </CardContent>
            </Card>
          </div>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
            <Card className="col-span-4">
              <CardHeader>
                <CardTitle>User Activity</CardTitle>
                <CardDescription>New users per month in {new Date().getFullYear()}</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[200px]">
                  {loading ? (
                    <div className="h-full w-full animate-pulse rounded bg-muted"></div>
                  ) : stats.monthlyUserData.every((count: number) => count === 0) ? (
                    <p className="text-center text-muted-foreground h-full flex items-center justify-center">
                      No user data available for {new Date().getFullYear()}.
                    </p>
                  ) : (
                    <Bar data={userChartData} options={userChartOptions} />
                  )}
                </div>
              </CardContent>
            </Card>
            <Card className="col-span-3">
              <CardHeader>
                <CardTitle>Recent Activity</CardTitle>
                <CardDescription>Latest user actions and content updates</CardDescription>
              </CardHeader>
              <CardContent>
                {loading ? (
                  <div className="space-y-4">
                    {[1, 2, 3, 4, 5].map((i) => (
                      <div key={i} className="flex items-center gap-4">
                        <div className="h-8 w-8 animate-pulse rounded-full bg-muted"></div>
                        <div className="space-y-2">
                          <div className="h-4 w-32 animate-pulse rounded bg-muted"></div>
                          <div className="h-3 w-24 animate-pulse rounded bg-muted"></div>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="space-y-4">
                    {stats.recentActivity.length > 0 ? (
                      stats.recentActivity.map((activity) => (
                        <div key={activity.id} className="flex items-center gap-4">
                          <div className="h-8 w-8 rounded-full bg-primary/20 flex items-center justify-center">
                            {getActivityIcon(activity.type)}
                          </div>
                          <div className="space-y-1">
                            <p className="text-sm font-medium">{activity.title}</p>
                            <p className="text-xs text-muted-foreground">{getTimeAgo(activity.timestamp)}</p>
                          </div>
                        </div>
                      ))
                    ) : (
                      <p className="text-center text-muted-foreground">No recent activity</p>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>
        <TabsContent value="analytics" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Blog Post Activity</CardTitle>
                <CardDescription>New blog posts per month in {new Date().getFullYear()}</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  {loading ? (
                    <div className="h-full w-full animate-pulse rounded bg-muted"></div>
                  ) : stats.monthlyBlogData.every((count: number) => count === 0) ? (
                    <p className="text-center text-muted-foreground h-full flex items-center justify-center">
                      No blog post data available for {new Date().getFullYear()}.
                    </p>
                  ) : (
                    <Bar data={blogChartData} options={chartOptions} />
                  )}
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle>Average Age of Event Participants</CardTitle>
                <CardDescription>Average age of users per event (2+ participants)</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  {loading ? (
                    <div className="h-full flex items-center justify-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                    </div>
                  ) : stats.eventAgeData.length > 0 ? (
                    <Line key={stats.eventAgeData.length} data={eventAgeChartData} options={chartOptions} />
                  ) : (
                    <p className="text-center text-muted-foreground h-full flex items-center justify-center">
                      No events with 2 or more participants available.
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}