# AI Agent Instructions for Rota Generator

## Project Overview
This is a Perl-based project for generating rotas (schedules/timetables). The project is currently in initial setup phase.

## Development Environment
- Project uses a dev container based on Ubuntu Linux for consistent development
- Key dev dependencies:
  - Perl (installed via apt)
  - VS Code with Perl Toolbox extension for Perl language support
  - Test2 suite for testing framework
  - yath test runner for enhanced test execution and reporting
  - Devel::Cover for code coverage analysis
  - Devel::NYTProf for performance profiling
  - Perl::Critic for static code analysis
  - Perl::Tidy for code formatting

## Project Structure
The project will follow standard Perl module/distribution structure:
```
lib/           # Perl modules
t/            # Test files
bin/          # Command line tools
dist.ini      # Distribution configuration (using Dist::Zilla)
cpanfile      # Module dependencies
```

### Dist::Zilla Usage
The project uses `dist.ini` for build and release management via Dist::Zilla. This provides:
- Automated version management
- Dependency tracking
- Documentation generation
- Release process automation

Example `dist.ini` configuration:
```ini
name    = Rota-Generator
author  = [Your Name]
license = Perl_5
copyright_holder = [Your Name]

[@Basic]         ; Basic plugin bundle
[AutoPrereqs]    ; Automatically detect prerequisites
[TestRelease]    ; Run tests before releasing
[ConfirmRelease] ; Confirm before releasing
[PodWeaver]      ; Process POD documentation

[Git::Check]     ; Ensure working directory is clean
[Git::Commit]    ; Commit changes after release
[Git::Tag]       ; Create a tag after release
[Git::Push]      ; Push changes and tags

; Development tools
[Test::Perl::Critic]
[PodCoverageTests]
[Test::Compile]
```

Key Dist::Zilla commands:
- `dzil build` - Build a distribution
- `dzil test` - Run tests
- `dzil release` - Release to CPAN
- `dzil authordeps` - List author dependencies
- `dzil listdeps` - List runtime dependencies

## Development Workflow
1. All development should happen inside the dev container to ensure consistency
2. Test-Driven Development (TDD) approach:
   - Write failing test first in `t/` directory
   - Implement code in `lib/` to make test pass
   - Refactor while keeping tests green
3. Perl module development conventions:
   - Modules go in `lib/` with proper namespace structure
   - Tests in `t/` matching module paths
   - POD documentation in modules
4. Testing and Quality Assurance:
   - Run tests with yath: `yath test t/`
   - Generate coverage reports: `cover -test`
   - Profile performance: `perl -d:NYTProf script.pl`
5. CI/CD Pipeline:
   - GitHub Actions workflow for automated testing
   - Code coverage reporting
   - Performance benchmarking baselines

## Code Style and Quality
- Code formatting is enforced using Perl::Tidy with PBP settings in `.perltidyrc`:
  ```
  --perl-best-practices        # Follow Perl Best Practices
  --maximum-line-length=120     # PBP line length
  --indent-columns=4          # 4 column indentation
  --standard-output           # Send output to STDOUT by default
  --standard-error-output     # Send errors to STDERR
  --warning-output           # Show warnings
  --check-syntax            # Check syntax before formatting
  ```

- Code quality is checked using Perl::Critic with configuration in `.perlcriticrc`:
  ```
  severity = 3                               # Default to stern (1-5)
  verbose = %f:%l:%c:[%p] %m\n              # Show file:line:column
  theme = core + pbp + security + maintenance # Include key themes

  # Common policy adjustments
  [Subroutines::ProhibitExcessComplexity]
  max_mccabe = 20

  [Documentation::RequirePodSections]
  lib_sections = NAME | SYNOPSIS | DESCRIPTION | METHODS | AUTHOR
  ```

### VS Code Integration
- The Perl Toolbox extension provides integrated support for:
  - Syntax highlighting
  - Code formatting with Perl::Tidy
  - Linting with Perl::Critic
  - Test runner integration
  - POD documentation preview

Configure VS Code settings.json for Perl integration:
```json
{
    "perl-toolbox.lint.perlcritic": true,
    "perl-toolbox.lint.useProfile": true,
    "perl-toolbox.lint.severity": 3,
    "perl-toolbox.format.enabled": true,
    "perl-toolbox.format.perltidyrc": "${workspaceFolder}/.perltidyrc",
    "[perl]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "d9705996.perl-toolbox"
    }
}
```

### Running Tools
- Format code: `perltidy -b [files]` or use Format Document in VS Code (Alt+Shift+F)
- Check code quality: `perlcritic [files]` or view problems in VS Code Problems panel
- Both tools are integrated into the CI pipeline and `dzil` release process

## Other Conventions
To be established as the codebase grows:
- Code organization patterns
- Testing approaches
- Documentation standards

## Key Files
- `.devcontainer/devcontainer.json` - Development container configuration
- `.gitignore` - Standard Perl project ignores

---
Note: These instructions are initial and should be updated as project patterns and conventions emerge through development.