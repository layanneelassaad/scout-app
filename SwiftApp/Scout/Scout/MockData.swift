import Foundation

// MARK: - Mock Toolsets
let githubToolset = Toolset(id: UUID(), name: "GitHub", description: "Integrate with GitHub repositories.", icon: "chevron.left.forwardslash.chevron.right", price: 0.0)
let mailToolset = Toolset(id: UUID(), name: "Mail", description: "Read and send emails.", icon: "envelope.fill", price: 0.0)
let calendarToolset = Toolset(id: UUID(), name: "Calendar", description: "Manage your calendar and events.", icon: "calendar", price: 0.0)
let blenderToolset = Toolset(id: UUID(), name: "Blender", description: "Create and manipulate 3D models.", icon: "cube.box.fill", price: 49.99)
let pythonToolset = Toolset(id: UUID(), name: "Data Analysis (Python)", description: "Analyze data using Python and popular libraries.", icon: "chart.bar.xaxis", price: 29.99)

let allToolsets = [githubToolset, mailToolset, calendarToolset, blenderToolset, pythonToolset]

// MARK: - Mock Agents
let modelerAgent = Agent(
    id: UUID(),
    name: "3D Modeler",
    description: "An agent specialized in creating 3D models using Blender.",
    icon: "person.fill.viewfinder",
    price: 99.99,
    rating: 4.8,
    reviewCount: 120,
    requiredToolsetIDs: [blenderToolset.id, githubToolset.id],
    dependentAgentIDs: []
)

let dataScientistAgent = Agent(
    id: UUID(),
    name: "Data Scientist",
    description: "Your personal data scientist for analyzing and visualizing data.",
    icon: "brain.head.profile",
    price: 149.99,
    rating: 4.9,
    reviewCount: 250,
    requiredToolsetIDs: [pythonToolset.id, githubToolset.id],
    dependentAgentIDs: []
)

let executiveAssistantAgent = Agent(
    id: UUID(),
    name: "Executive Assistant",
    description: "Manages your email, calendar, and schedules meetings.",
    icon: "person.crop.circle.badge.checkmark",
    price: 0.0,
    rating: 4.5,
    reviewCount: 540,
    requiredToolsetIDs: [mailToolset.id, calendarToolset.id],
    dependentAgentIDs: []
)

let fileSearchAgent = Agent(
    id: UUID(),
    name: "File Search",
    description: "Search and analyze files on your system with advanced filtering.",
    icon: "magnifyingglass.circle.fill",
    price: 0.0,
    rating: 4.7,
    reviewCount: 89,
    requiredToolsetIDs: [],
    dependentAgentIDs: []
)

let allAgents = [fileSearchAgent, modelerAgent, dataScientistAgent, executiveAssistantAgent]
