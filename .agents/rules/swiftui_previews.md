# SwiftUI Previews Rule

Always include a `#Preview` block for every SwiftUI View, sheet, modal, and component created or modified.

Guidelines:
- Ensure the preview provides realistic mock data or default state so it renders immediately in Xcode canvas without crashing.
- For sheet or modal views, provide both a container preview showing how it presents and a standalone view preview if appropriate.
- Test preview compatibility with dark mode where applicable.
