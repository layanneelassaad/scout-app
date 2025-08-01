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
  name: "Report Generator",
  description: "Creates detailed reports by extracting info from emails, Slack, Teams, PDFs, and more.",
  icon: "doc.plaintext",
  price: 0.99,
  rating: 4.5,
  reviewCount: 2,
  requiredToolsetIDs: [],
  dependentAgentIDs: [],
  categories: [Category.madeByScout],
  requiredPermissions: ["Accessibility"],
  recommendedPermissions: ["Full Disk Access"],
  infoPage: nil,
  permissionsPage: nil
)

let emailTriageAgent = Agent(
  id: UUID(),
  apiID: "email-triage-draft",
  name: "Email Responder",
  description: "Draft responses for emails in your inbox. Based on the way you like to respond.",
  icon: "envelope.open",
  price: 0.0,
  rating: 5,
  reviewCount: 1,
  requiredToolsetIDs: [],
  dependentAgentIDs: [],
  categories: [Category.madeByScout],
  requiredPermissions: ["Mail Access"],
  recommendedPermissions: ["Contacts", "Calendar Access", "Reminders"],
  infoPage: nil,
  permissionsPage: nil
)

let meetingNoteAgent = Agent(
  id: UUID(),
  apiID: "meeting-note-taker",
  name: "Meeting Note-Taker",
  description: "Transcribes meetings, creates todo lists, and links tasks to your projects.",
  icon: "mic.fill",
  price: 0.0,
  rating: 4,
  reviewCount: 2,
  requiredToolsetIDs: [],
  dependentAgentIDs: [],
  categories: [Category.madeByScout],
  requiredPermissions: ["Microphone"],
  recommendedPermissions: ["Screen Recording", "Full Disk Access", "Calendar Access"],
  infoPage: nil,
  permissionsPage: nil
)


let fileSearchAgent = Agent(
    id: UUID(),
    apiID:"file-search",
    name: "Search Agent",
    description: "Find anything on your computer in seconds using natural language.",
    icon: "magnifyingglass.circle.fill",
    price: 0.0,
    rating: 5,
    reviewCount: 2,
    requiredToolsetIDs: [],
    dependentAgentIDs: [],
    categories: [Category.madeByScout],
    requiredPermissions: ["Limited Disk Access (Select Specific)"],
    recommendedPermissions: ["Full Disk Access", "Knowledge Graph"],
    infoPage: InfoPageContent.searchAgent,
    permissionsPage: PermissionsPage.searchAgent
)

// slide deck creator?

let allAgents = [fileSearchAgent,
                 summarizerAgent,
                 emailTriageAgent, meetingNoteAgent]
