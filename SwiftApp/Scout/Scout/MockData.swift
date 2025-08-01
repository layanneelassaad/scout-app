import Foundation

// MARK: - Mock Toolsets
let githubToolset = Toolset(id: UUID(), name: "GitHub", description: "Integrate with GitHub repositories.", icon: "chevron.left.forwardslash.chevron.right", price: 0.0)
let mailToolset = Toolset(id: UUID(), name: "Mail", description: "Read and send emails.", icon: "envelope.fill", price: 0.0)
let calendarToolset = Toolset(id: UUID(), name: "Calendar", description: "Manage your calendar and events.", icon: "calendar", price: 0.0)
let blenderToolset = Toolset(id: UUID(), name: "Blender", description: "Create and manipulate 3D models.", icon: "cube.box.fill", price: 49.99)
let pythonToolset = Toolset(id: UUID(), name: "Data Analysis (Python)", description: "Analyze data using Python and popular libraries.", icon: "chart.bar.xaxis", price: 29.99)

let allToolsets = [githubToolset, mailToolset, calendarToolset, blenderToolset, pythonToolset]

// MARK: - Mock Agents

let summarizerAgent = Agent(
  id: UUID(),
  apiID: "cross-app-summarizer",
  name: "Cross-App Summarizer",
  description: "Extracts and condenses info from emails, Slack, Teams, PDFs, and web pages with smart AI.",
  icon: "doc.plaintext",
  price: 7.99,
  rating: 4.5,
  reviewCount: 2,
  requiredToolsetIDs: [],
  dependentAgentIDs: [],
  categories: ["made by scout"],
  requiredPermissions: ["Full Disk Access", "Accessibility"],
  recommendedPermissions: ["Microphone", "Camera"]
)

let emailTriageAgent = Agent(
  id: UUID(),
  apiID: "email-triage-draft",
  name: "Email Triage & Draft",
  description: "Sorts, filters, drafts replies, and schedules follow-ups on your inbox.",
  icon: "envelope.open",
  price: 7.99,
  rating: 5,
  reviewCount: 1,
  requiredToolsetIDs: [],
  dependentAgentIDs: [],
  categories: ["made by scout"],
  requiredPermissions: ["Mail Access", "Calendar Access"],
  recommendedPermissions: ["Contacts", "Reminders"]
)

let meetingNoteAgent = Agent(
  id: UUID(),
  apiID: "meeting-note-taker",
  name: "Meeting Note-Taker",
  description: "Transcribes meetings, highlights actions, and links tasks to your projects.",
  icon: "mic.fill",
  price: 6.99,
  rating: 4,
  reviewCount: 2,
  requiredToolsetIDs: [],
  dependentAgentIDs: [],
  categories: ["made by scout"],
  requiredPermissions: ["Microphone", "Screen Recording"],
  recommendedPermissions: ["Camera", "Full Disk Access"]
)


let fileSearchAgent = Agent(
    id: UUID(),
    apiID:"file-search",
    name: "File Scout",
    description: "Search and analyze files on your system with advanced filtering.",
    icon: "magnifyingglass.circle.fill",
    price: 0.0,
    rating: 5,
    reviewCount: 2,
    requiredToolsetIDs: [],
    dependentAgentIDs: [],
    categories: ["made by scout"],
    requiredPermissions: ["Full Disk Access"],
    recommendedPermissions: ["Accessibility", "Automation"]
)

let allAgents = [fileSearchAgent,
                 summarizerAgent,
                 emailTriageAgent, meetingNoteAgent]
