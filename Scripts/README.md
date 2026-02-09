# GitHub Issue Creation Scripts

This directory contains scripts for automating the creation of GitHub issues from implementation plans.

## Files

- **`create-issues.js`** - Main script that creates GitHub issues from configuration
- **`issue-config.json`** - Issue metadata, labels, and specifications
- **`package.json`** - Node.js package configuration
- **`ISSUE_CREATION_SUMMARY.md`** - Summary of created issues

## Prerequisites

1. **GitHub CLI** installed and authenticated:
   ```bash
   gh auth status
   gh auth login  # if needed
   ```

2. **Node.js** (v18 or later recommended):
   ```bash
   node --version
   ```

## Usage

### Create Issues

```bash
cd scripts
node create-issues.js
```

The script will:
1. Create all necessary labels if they don't exist
2. Create issues in dependency order
3. Cross-reference dependencies between issues
4. Output a summary with issue numbers

### View Created Issues

```bash
# List all issues
gh issue list --limit 20

# View specific issue
gh issue view 107

# List issues by label
gh issue list --label infrastructure
gh issue list --label testing
```

## Issue Configuration

The `issue-config.json` file defines:

- **labels** - Label names and colors
- **issues** - Array of issue specifications with:
  - `id` - Local issue ID (for dependency tracking)
  - `phase` - Implementation phase
  - `title` - Issue title
  - `labels` - Array of label names
  - `dependencies` - Array of issue IDs this depends on
  - `files` - Files to create/modify
  - `spec` - Specification text
  - `acceptance` - Array of acceptance criteria

## Adding New Issues

To add new issues:

1. Edit `issue-config.json`
2. Add new issue object to the `issues` array
3. Ensure dependencies reference existing issue IDs
4. Run `node create-issues.js`

## Script Features

- **Dependency Handling** - Creates issues in order, cross-references dependencies
- **Label Management** - Creates missing labels automatically
- **Error Handling** - Continues on errors, reports failures
- **Rate Limiting** - Small delays between API calls
- **Summary Output** - Maps local IDs to GitHub issue numbers

## Example Output

```
GitHub Issue Creator for skit-analyze-plan.md
==================================================

Step 1: Creating labels...
  Created label: infrastructure
  Label "enhancement" already exists
  ...

Step 2: Creating issues...

Creating issue 1: Setup OpenAPI Specification and Generator Configuration
  Created issue #107: Setup OpenAPI Specification and Generator Configuration

Creating issue 2: Update Package.swift with Dependencies and Targets
  Created issue #108: Update Package.swift with Dependencies and Targets
  ...

==================================================
Summary:
  Total issues created: 18 / 18

Issue mapping:
  Issue 1 -> #107: Setup OpenAPI Specification and Generator Configuration
  Issue 2 -> #108: Update Package.swift with Dependencies and Targets
  ...
```

## Troubleshooting

### GitHub CLI Not Authenticated

```bash
gh auth login
```

### Label Already Exists Error

This is expected - the script handles existing labels gracefully.

### Issue Creation Failed

Check the error message. Common issues:
- Network connectivity
- API rate limiting (add delays in script)
- Invalid characters in title/body (check escaping)

## Customization

### Changing Label Colors

Edit the `labels` object in `issue-config.json`:

```json
"labels": {
  "infrastructure": "0052CC",
  "custom-label": "FF0000"
}
```

### Modifying Issue Template

Edit the `formatIssueBody()` function in `create-issues.js` to change the issue body format.

## Related Documentation

- [skit-analyze-plan.md](../Docs/skit-analyze-plan.md) - Full implementation plan
- [ISSUE_CREATION_SUMMARY.md](./ISSUE_CREATION_SUMMARY.md) - Summary of created issues
