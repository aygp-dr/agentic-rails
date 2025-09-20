# Progressive Commit Protocol for Terminal Agents

## Core Principles
- Commit incrementally as work progresses
- Include tests with each meaningful change
- Partial commits are acceptable if they advance the project

## Commit Strategy
1. **Add and commit** during active development
2. **Test coverage** should accompany functional changes
3. **Partial work** is committable when it represents forward progress

## Post-Commit Documentation
After each commit, add comprehensive git notes covering:

### Technical Context
- Architecture decisions and rationale
- Testing approach and coverage
- Implementation thought process
- Technical trade-offs made

### Project Evolution
- Experiments conducted
- Deviations from original plan
- Issues encountered and resolutions
- Alternative approaches considered

### Reproducibility Goal
Document sufficiently that another agent could:
- Understand the development journey
- Recreate the project from scratch
- Learn from both successes and dead-ends

## Implementation for Agentic Rails

### Commit Hooks
```bash
# .git/hooks/prepare-commit-msg
#!/bin/bash
# Auto-add risk assessment to commit messages
echo "" >> $1
echo "Risk Assessment:" >> $1
echo "- Feature Risk: [LOW/MEDIUM/HIGH]" >> $1
echo "- Dependency Risk: [LOW/MEDIUM/HIGH]" >> $1
echo "- Performance Impact: [NONE/MINIMAL/SIGNIFICANT]" >> $1
```

### Git Note Categories
1. **ARCH**: Architecture decisions
2. **RISK**: Risk assessments and mitigations
3. **PERF**: Performance considerations
4. **TEST**: Testing strategy
5. **EXP**: Experiments and learnings

### Example Workflow
```bash
# Make incremental changes
git add app/models/concerns/risk_aware.rb
git commit -m "feat: add risk-aware model concern

Risk Assessment:
- Feature Risk: MEDIUM (new abstraction)
- Dependency Risk: LOW (no external deps)
- Performance Impact: MINIMAL (lightweight calculations)"

# Add comprehensive notes
git notes add -m "ARCH: Implemented risk scoring as a concern to ensure all models can participate in risk assessment. Used weighted scoring algorithm based on Risk-First principles.

RISK: This concern adds database columns (risk_score, risk_assessed_at) to implementing models. Migration strategy needed for existing tables.

TEST: Unit tests cover risk calculation logic. Integration tests verify ActionCable broadcasting.

PERF: Risk calculations are performed on save, adding ~5ms overhead. Consider moving to background job for large datasets."
```

### Automated Documentation
```ruby
# lib/tasks/document.rake
namespace :git do
  desc "Generate commit documentation"
  task :document do
    commits = `git log --pretty=format:'%H|%s|%an|%ai'`.split("\n")

    File.open('COMMIT_LOG.md', 'w') do |f|
      f.puts "# Development Journey\n\n"

      commits.each do |commit|
        hash, subject, author, date = commit.split('|')
        notes = `git notes show #{hash} 2>/dev/null`

        f.puts "## #{subject}"
        f.puts "- Commit: #{hash[0..7]}"
        f.puts "- Date: #{date}"
        f.puts "\n#{notes}\n" unless notes.empty?
        f.puts "---\n"
      end
    end
  end
end
```