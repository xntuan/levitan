# Quick Start Guide for Development Agents
## Pattern Drawing App - "Ink"

**Version:** 1.0  
**Last Updated:** November 10, 2025

---

## 🚀 Welcome!

You've been assigned to help build a meditative pattern drawing app. This guide will help you understand the project and know where to start.

---

## 📚 Document Overview

You have **4 main documents**. Here's what each contains:

### 1. **PRD (Product Requirements Document)**
`01-PRD-Product-Requirements.md`

**What it contains:**
- What the app does (user perspective)
- User stories & use cases
- Feature requirements
- Success metrics

**When to read:** 
- Before starting ANY task
- When unclear about feature purpose
- When making product decisions

**Key sections:**
- Section 3: User Stories (understand user needs)
- Section 4: Feature Requirements (what to build)
- Section 7: Success Criteria (how to measure)

---

### 2. **Technical Specification**
`02-Technical-Specification.md`

**What it contains:**
- How to build features (technical details)
- Architecture & system design
- Code examples & algorithms
- Data models & file formats

**When to read:**
- Before coding any feature
- When implementing algorithms
- When designing APIs

**Key sections:**
- Section 2: Architecture (system structure)
- Section 3: Core Systems (algorithms)
- Section 4: Data Models (file formats)
- Section 5: Performance (optimization)

---

### 3. **UI/UX Design Brief**
`03-UI-UX-Design-Brief.md`

**What it contains:**
- Visual design guidelines (Lake aesthetic)
- Component specifications
- Animation details
- Accessibility requirements

**When to read:**
- Before building any UI
- When styling components
- When implementing animations

**Key sections:**
- Section 2: Lake Aesthetic (colors, fonts, spacing)
- Section 3: Component Library (buttons, cards, etc.)
- Section 4: Screen Layouts (complete screens)
- Section 5: Interaction Patterns (gestures, transitions)

---

### 4. **Development Roadmap**
`04-Development-Roadmap.md` (this affects you most!)

**What it contains:**
- Task breakdown (what to build when)
- Dependencies (what blocks what)
- Agent assignments (who does what)
- Timeline (how long)

**When to read:**
- At start of each sprint/week
- When picking next task
- When blocked by dependencies

**Key sections:**
- Section 2: Phase 1 Tasks (detailed task list)
- Section 6: Agent Roles (your responsibilities)
- Section 7: Communication (how to sync)

---

## 🎯 How to Get Started

### Step 1: Identify Your Role

**Are you a:**
- **Backend Agent?** → Data, file I/O, models
- **Graphics Agent?** → Metal, rendering, shaders
- **UI Agent?** → View controllers, UI components
- **Integration Agent?** → Connecting modules
- **Performance Agent?** → Optimization, profiling
- **Content Agent?** → Templates, assets
- **DevOps Agent?** → Build, deploy, TestFlight
- **Marketing Agent?** → App Store, marketing

### Step 2: Read Your Section in Roadmap

Go to `04-Development-Roadmap.md`, Section 6: Agent Assignment Guide

Find your role and read:
- Responsibilities
- Skills needed
- Common tasks

### Step 3: Check Current Phase

Look at Section 2 in Roadmap to see which phase we're in:
- **Phase 1 (Weeks 1-8):** Core development
- **Phase 2 (Weeks 9-10):** Beta testing
- **Phase 3 (Weeks 11-14):** Content creation
- **Phase 4 (Weeks 15-16):** Launch prep

### Step 4: Find Your Next Task

In the Roadmap, find tasks assigned to your role in the current phase.

Each task has:
- **Task ID** (e.g., Task 1.1)
- **Duration** (estimated time)
- **Dependencies** (what must finish first)
- **Deliverables** (what to build)
- **Implementation Guide** (code examples)
- **Acceptance Criteria** (definition of done)

### Step 5: Read Related Documents

Before coding, read:
1. **PRD** → Understand WHY you're building this
2. **Technical Spec** → Understand HOW to build it
3. **UI/UX Brief** → Understand how it should LOOK (if UI task)

---

## 🔍 Task Execution Checklist

Before starting a task:
- [ ] Read task description in Roadmap
- [ ] Check dependencies are complete
- [ ] Read relevant PRD sections
- [ ] Read relevant Technical Spec sections
- [ ] Read relevant UI/UX sections (if applicable)
- [ ] Understand acceptance criteria
- [ ] Have all required resources (assets, etc.)

While working:
- [ ] Follow code examples in Technical Spec
- [ ] Follow design guidelines in UI/UX Brief
- [ ] Write clean, documented code
- [ ] Add comments explaining complex logic
- [ ] Test as you go

Before marking complete:
- [ ] All acceptance criteria met
- [ ] Code compiles without warnings
- [ ] Manual testing done
- [ ] Performance acceptable
- [ ] Committed to git with clear message

---

## 📖 Common Workflows

### Workflow 1: Implementing a UI Component

1. **Read UI/UX Brief**, Section 3 (Component Library)
2. Find your component (e.g., "Primary Button")
3. Note all specifications:
   - Colors
   - Sizes
   - Radius
   - Shadows
   - States
   - Animations
4. **Read Technical Spec**, Section 8 (Design Tokens)
5. Use provided constants (don't hardcode!)
6. Implement component
7. Test all states (default, pressed, disabled)
8. Verify matches design pixel-perfect

### Workflow 2: Implementing a Feature

1. **Read PRD**, find feature in Section 4
2. Understand user story and requirements
3. **Read Technical Spec**, find implementation guide
4. Study code examples
5. **Read Roadmap**, find your task
6. Check acceptance criteria
7. Implement feature
8. Test against acceptance criteria
9. Update task checklist

### Workflow 3: Fixing a Bug

1. Reproduce bug
2. **Read Technical Spec** for relevant system
3. Identify root cause
4. Implement fix
5. Test fix works
6. Test no regressions
7. Document fix in commit message

---

## 🗣️ Communication Guidelines

### Daily Updates

Post in team channel:
```
[Your Role] - Daily Update - [Date]

✅ Completed:
- Task 1.1: Project setup
- Task 1.2: Metal renderer (80% done)

🚧 In Progress:
- Task 1.3: Canvas view controller

❌ Blocked:
- Need X from [Agent Name]

📅 Tomorrow:
- Finish Task 1.2
- Start Task 1.3
```

### Asking for Help

When blocked, post:
```
[Your Role] - Help Needed

Task: Task 1.2 - Metal Renderer
Issue: Shader compilation error
Error: [paste error]
What I tried: [list attempts]
Question: [specific question]
```

### Code Review Request

When ready for review:
```
[Your Role] - Code Review Request

Task: Task 1.2 - Metal Renderer
PR: [link to pull request]
Changes: [brief description]
Testing: [what you tested]
Reviewers: @GraphicsAgent @IntegrationAgent
```

---

## 🎨 Design Implementation Tips

### Colors
```swift
// ✅ DO: Use design tokens
button.backgroundColor = .inkPrimary

// ❌ DON'T: Hardcode colors
button.backgroundColor = UIColor(red: 0.4, green: 0.5, blue: 0.9, alpha: 1.0)
```

### Spacing
```swift
// ✅ DO: Use spacing constants
stackView.spacing = .spacingLG

// ❌ DON'T: Magic numbers
stackView.spacing = 16
```

### Animations
```swift
// ✅ DO: Use specified durations
UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
    view.alpha = 1.0
}

// ❌ DON'T: Random durations
UIView.animate(withDuration: 0.25) { ... }
```

---

## 🐛 Common Pitfalls to Avoid

### 1. Not Reading Documents
**Mistake:** Jump into coding without reading specs  
**Result:** Build wrong thing, waste time  
**Solution:** Always read PRD + Spec first

### 2. Hardcoding Values
**Mistake:** Use magic numbers for colors, spacing, etc.  
**Result:** Inconsistent design, hard to maintain  
**Solution:** Use design tokens from UI/UX Brief

### 3. Ignoring Dependencies
**Mistake:** Start task before dependencies complete  
**Result:** Blocked, wasted time  
**Solution:** Check Roadmap dependencies first

### 4. Skipping Testing
**Mistake:** Mark task complete without testing  
**Result:** Bugs in production  
**Solution:** Test against acceptance criteria

### 5. Poor Communication
**Mistake:** Work in silence, don't ask for help  
**Result:** Duplicate work, wrong implementation  
**Solution:** Daily updates, ask questions early

---

## 🧪 Testing Guidelines

### Unit Tests
Every feature should have unit tests:
```swift
// Example from Technical Spec
class BrushEngineTests: XCTestCase {
    func testParallelLineGeneration() {
        // Setup
        let brush = PatternBrush(type: .parallelLines, rotation: 45, spacing: 10)
        
        // Execute
        let lines = brushEngine.generateParallelLines(center: CGPoint(x: 100, y: 100), brush: brush)
        
        // Assert
        XCTAssertEqual(lines.count, 7)
        XCTAssertTrue(lines[0].start.x < lines[0].end.x)
    }
}
```

### Manual Testing
Before marking task complete:
1. Run app on simulator
2. Test feature thoroughly
3. Try edge cases
4. Check performance
5. Verify visual design

### Device Testing
Test on multiple devices:
- iPad Pro (latest)
- iPad Air
- iPhone 13 Pro
- iPad (9th gen) - minimum spec

---

## 📦 Deliverable Standards

### Code Quality
- Clear variable names
- Documented complex logic
- No compiler warnings
- Follows Swift style guide

### Git Commits
```
Good commit message:
"[Task 1.2] Implement Metal renderer with shader pipeline"

Bad commit message:
"fix stuff"
"wip"
"update"
```

### Pull Requests
Include:
- Task number and description
- What changed
- How to test
- Screenshots (if UI)
- Reviewers tagged

---

## 🎓 Learning Resources

### If you're new to Metal:
1. Read Technical Spec, Section 3.3 (Metal Rendering)
2. Apple Metal docs: https://developer.apple.com/metal/
3. Sample code in Technical Spec

### If you're new to iOS UI:
1. Read UI/UX Brief completely
2. Apple HIG: https://developer.apple.com/design/human-interface-guidelines/
3. Lake app (reference for aesthetic)

### If you're new to Core Graphics:
1. Read Technical Spec, Section 3.4 (Layer Mask System)
2. Apple Core Graphics: https://developer.apple.com/documentation/coregraphics

---

## 🚦 Current Status

Check Roadmap for current status of all tasks.

**How to update status:**
1. Find your task in Roadmap
2. Update checkbox: [ ] → [x]
3. Commit change to git
4. Post in team channel

---

## 🆘 Who to Contact

**Questions about:**
- **Product/Features** → Read PRD, ask Product Team
- **Technical Implementation** → Read Technical Spec, ask Graphics/Backend Agent
- **Design/UI** → Read UI/UX Brief, ask UI Agent
- **Timeline/Tasks** → Read Roadmap, ask Integration Agent
- **Blockers** → Post in team channel immediately

---

## 🎯 Quick Reference

### Most Important Sections to Bookmark

**For Backend Agents:**
- Technical Spec, Section 4: Data Models
- Roadmap, Week 1-2 Tasks

**For Graphics Agents:**
- Technical Spec, Section 3: Core Systems
- Technical Spec, Section 3.3: Metal Rendering
- Roadmap, Week 3-4 Tasks

**For UI Agents:**
- UI/UX Brief, Section 2: Lake Aesthetic
- UI/UX Brief, Section 3: Component Library
- UI/UX Brief, Section 4: Screen Layouts
- Roadmap, Week 5-6 Tasks

**For All Agents:**
- PRD, Section 4: Feature Requirements
- Roadmap, Section 6: Agent Assignment
- Roadmap, Section 7: Communication Protocol

---

## 🎬 Let's Build!

You're ready to start! Here's your action plan:

**Right now:**
1. ✅ You've read this Quick Start Guide
2. 📖 Read your agent role in Roadmap (Section 6)
3. 🎯 Find your first task in Roadmap (Section 2)
4. 📚 Read related sections in PRD, Technical Spec, UI/UX Brief
5. 💻 Start coding!

**Remember:**
- Read before you code
- Test as you go
- Communicate daily
- Ask questions early
- Have fun building! 🚀

---

## 📞 Support

If you're stuck after reading all documents:
1. Check FAQ below
2. Search documents for keywords
3. Ask in team channel
4. Tag relevant agent for help

---

## ❓ FAQ

**Q: Which document should I read first?**  
A: This Quick Start Guide (you're here!), then your role in Roadmap, then PRD for context.

**Q: Do I need to read ALL documents?**  
A: No. Read Quick Start, then sections relevant to your task. Use documents as reference.

**Q: What if I disagree with a design decision?**  
A: Follow the spec for MVP. Note your concern in code comment. Discuss after MVP ships.

**Q: Can I change the technical approach?**  
A: For minor improvements, yes (document in PR). For major changes, discuss with team first.

**Q: What if my task is blocked?**  
A: Post in team channel immediately. Work on non-blocked task while waiting.

**Q: How do I know if I'm doing it right?**  
A: Check acceptance criteria in Roadmap. If met, you're good!

**Q: Should I optimize for performance now?**  
A: Make it work first, then optimize if needed. Performance Agent will profile later.

**Q: What if I finish early?**  
A: Great! Pick next task from your section in Roadmap, or help others.

---

**Good luck! You've got this! 💪✨**

---

*Last updated: November 10, 2025*  
*Questions? Post in team channel with @all*
