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
  rating: 4.3,
  reviewCount: 512,
  requiredToolsetIDs: [],
  dependentAgentIDs: []
)

let emailTriageAgent = Agent(
  id: UUID(),
  apiID: "email-triage-draft",
  name: "Email Triage & Draft",
  description: "Sorts, filters, drafts replies, and schedules follow-ups on your inbox.",
  icon: "envelope.open",
  price: 7.99,
  rating: 4.2,
  reviewCount: 478,
  requiredToolsetIDs: [],
  dependentAgentIDs: []
)

let meetingNoteAgent = Agent(
  id: UUID(),
  apiID: "meeting-note-taker",
  name: "Meeting Note-Taker",
  description: "Transcribes meetings, highlights actions, and links tasks to your projects.",
  icon: "mic.fill",
  price: 6.99,
  rating: 4.4,
  reviewCount: 390,
  requiredToolsetIDs: [],
  dependentAgentIDs: []
)


let fileSearchAgent = Agent(
    id: UUID(),
    apiID:"meeting-note-taker",
    name: "File Search",
    description: "Search and analyze files on your system with advanced filtering.",
    icon: "magnifyingglass.circle.fill",
    price: 0.0,
    rating: 4.7,
    reviewCount: 89,
    requiredToolsetIDs: [],
    dependentAgentIDs: []
)

let allAgents = [fileSearchAgent,
                 summarizerAgent,
                 emailTriageAgent, meetingNoteAgent]
