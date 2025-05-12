# Flutter Supabase Clean Architecture Rules

## Project Structure
- Use feature-first folder structure with clean architecture layers
- Maintain separation between presentation, domain, and data layers
- Group related files in feature modules
- Keep core utilities, themes, and DI setup in dedicated folders

## Clean Architecture Principles
- Presentation layer: UI components, BLoCs, pages, widgets
- Domain layer: Business logic, entities, use cases, repository interfaces
- Data layer: Repository implementations, data sources, models, DTOs
- Dependencies flow inward: data → domain ← presentation
- Domain layer must not depend on Flutter or external packages
- Use mappers to convert between data models and domain entities

## State Management
- Use flutter_bloc package for all state management
- Create separate event, state, and bloc classes for each feature
- Follow naming convention: FeatureBloc, FeatureEvent, FeatureState
- Keep BLoCs focused on single responsibility
- Use Equatable for comparing states and events
- Handle loading, success, and error states explicitly

## Dependency Injection
- Use GetIt for service locator pattern
- Register all dependencies in a centralized injection container
- Lazy-initialize dependencies when possible
- Inject repositories into use cases, use cases into BLoCs

## Supabase Integration
- Abstract Supabase operations behind repository interfaces
- Handle all network errors and edge cases
- Use proper data models for Supabase responses
- Implement caching strategies where appropriate
- Secure API keys and sensitive data

## UI Guidelines
- Use Material 3 design system
- Create responsive layouts with MediaQuery and LayoutBuilder
- Implement dark/light theme support
- Use custom themes for consistent styling
- Break complex UIs into smaller, reusable components
- Implement proper loading and error states in UI
- Ensure accessibility compliance

## Code Quality
- Follow Dart style guide and effective Dart principles
- Use strong typing and avoid dynamic types
- Make all code null-safe
- Write meaningful comments for complex logic
- Use const constructors when possible
- Implement proper error handling with try/catch

## Testing
Only when asked to write test, following these rules:
- Write unit tests for domain and data layers
- Test BLoCs with bloc_test package
- Use mocks for external dependencies
- Aim for high test coverage of business logic

## Best Practices
- Use async/await for asynchronous operations
- Implement proper form validation
- Follow single responsibility principle
- Use named parameters for clarity
- Avoid widget rebuilds with const and selective state management
- Use extension methods for cleaner code
- Follow immutability principles where possible
- 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. 

## Feature Implementation Process
- Define domain entities and use cases first
- Implement repository interfaces in domain layer
- Create data sources and repository implementations
- Develop BLoC classes with events and states
- Build UI components last, consuming the BLoC
- Always follow the dependency rule: outer layers depend on inner layers