import Foundation

// MARK: - Mock Toolsets
let githubToolset = Toolset(id: UUID(), name: "GitHub", description: "Integrate with GitHub repositories.", icon: "chevron.left.forwardslash.chevron.right", price: 0.0)
let mailToolset = Toolset(id: UUID(), name: "Mail", description: "Read and send emails.", icon: "envelope.fill", price: 0.0)
let calendarToolset = Toolset(id: UUID(), name: "Calendar", description: "Manage your calendar and events.", icon: "calendar", price: 0.0)
let blenderToolset = Toolset(id: UUID(), name: "Blender", description: "Create and manipulate 3D models.", icon: "cube.box.fill", price: 49.99)
let pythonToolset = Toolset(id: UUID(), name: "Data Analysis (Python)", description: "Analyze data using Python and popular libraries.", icon: "chart.bar.xaxis", price: 29.99)

let allToolsets = [githubToolset, mailToolset, calendarToolset, blenderToolset, pythonToolset]

// MARK: - Mock Agents

let fileSearchAgentID = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!

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
  categories: ["made by scout"],
  requiredPermissions: ["Accessibility"],
  recommendedPermissions: ["Full Disk Access"]
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
  categories: ["made by scout"],
  requiredPermissions: ["Mail Access"],
  recommendedPermissions: ["Contacts", "Calendar Access", "Reminders"]
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
  categories: ["made by scout"],
  requiredPermissions: ["Microphone"],
  recommendedPermissions: ["Screen Recording", "Full Disk Access", "Calendar Access"]
)


let fileSearchAgent = Agent(
    id: fileSearchAgentID,
    apiID:"file-search",
    name: "File Scout",
    description: "Surface any information xyz.",
    icon: "magnifyingglass.circle.fill",
    price: 0.0,
    rating: 5,
    reviewCount: 2,
    requiredToolsetIDs: [],
    dependentAgentIDs: [],
    categories: ["made by scout"],
    requiredPermissions: [""],
    recommendedPermissions: ["Full Disk Access"]
)

// slide deck creator?

let allAgents = [fileSearchAgent,
                 summarizerAgent,
                 emailTriageAgent, meetingNoteAgent]
