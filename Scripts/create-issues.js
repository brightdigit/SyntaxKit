#!/usr/bin/env node

import { readFileSync } from 'fs';
import { execSync } from 'child_process';

// Load configuration
const config = JSON.parse(readFileSync('./issue-config.json', 'utf8'));

// Function to execute shell command and return output
function exec(command) {
  try {
    return execSync(command, { encoding: 'utf8' }).trim();
  } catch (error) {
    console.error(`Error executing command: ${command}`);
    console.error(error.message);
    throw error;
  }
}

// Function to check if a label exists
function labelExists(label) {
  try {
    exec(`gh label list --limit 1000 --json name --jq '.[] | select(.name=="${label}") | .name'`);
    return true;
  } catch {
    return false;
  }
}

// Function to create a label if it doesn't exist
function createLabel(name, color) {
  if (labelExists(name)) {
    console.log(`  Label "${name}" already exists`);
    return;
  }

  try {
    exec(`gh label create "${name}" --color "${color}" --description ""`);
    console.log(`  Created label: ${name}`);
  } catch (error) {
    console.error(`  Failed to create label: ${name}`);
  }
}

// Function to format issue body
function formatIssueBody(issue, createdIssues) {
  const phaseSection = `## Phase\n\n${issue.phase}\n`;

  const specSection = `## Specification\n\n${issue.spec}\n`;

  const acceptanceSection = `## Acceptance Criteria\n\n${issue.acceptance.map(c => `- [ ] ${c}`).join('\n')}\n`;

  const dependenciesSection = issue.dependencies.length > 0
    ? `## Dependencies\n\n${issue.dependencies.map(depId => {
        const ghIssueNum = createdIssues.get(depId);
        return ghIssueNum ? `- Depends on: #${ghIssueNum}` : `- Depends on: Issue ${depId} (to be created)`;
      }).join('\n')}\n`
    : '';

  const filesSection = issue.files.length > 0
    ? `## Files to Create/Modify\n\n${issue.files.map(f => `- \`${f}\``).join('\n')}\n`
    : '';

  const relatedSection = `## Related Documentation\n\n- [skit-analyze-plan.md](../blob/main/Docs/skit-analyze-plan.md)\n`;

  return [phaseSection, specSection, acceptanceSection, dependenciesSection, filesSection, relatedSection]
    .filter(s => s)
    .join('\n');
}

// Function to create a GitHub issue
function createIssue(issue, createdIssues) {
  const body = formatIssueBody(issue, createdIssues);
  const labels = issue.labels.join(',');

  // Escape special characters in title and body for shell
  const escapedTitle = issue.title.replace(/"/g, '\\"');
  const escapedBody = body.replace(/"/g, '\\"').replace(/`/g, '\\`');

  try {
    const result = exec(`gh issue create --title "${escapedTitle}" --body "${escapedBody}" --label "${labels}"`);
    // Extract issue number from URL (format: https://github.com/owner/repo/issues/123)
    const match = result.match(/issues\/(\d+)/);
    if (match) {
      const issueNumber = parseInt(match[1], 10);
      console.log(`  Created issue #${issueNumber}: ${issue.title}`);
      return issueNumber;
    }
  } catch (error) {
    console.error(`  Failed to create issue: ${issue.title}`);
    console.error(`  Error: ${error.message}`);
  }

  return null;
}

// Main execution
async function main() {
  console.log('GitHub Issue Creator for skit-analyze-plan.md');
  console.log('='.repeat(50));

  // Step 1: Create labels
  console.log('\nStep 1: Creating labels...');
  Object.entries(config.labels).forEach(([name, color]) => {
    createLabel(name, color);
  });

  // Step 2: Create issues in dependency order
  console.log('\nStep 2: Creating issues...');
  const createdIssues = new Map(); // Maps local issue ID to GitHub issue number

  // Sort issues by ID to ensure dependencies are created first
  const sortedIssues = config.issues.sort((a, b) => a.id - b.id);

  for (const issue of sortedIssues) {
    console.log(`\nCreating issue ${issue.id}: ${issue.title}`);

    // Check if all dependencies have been created
    const missingDeps = issue.dependencies.filter(depId => !createdIssues.has(depId));
    if (missingDeps.length > 0) {
      console.log(`  Warning: Missing dependencies: ${missingDeps.join(', ')}`);
    }

    const issueNumber = createIssue(issue, createdIssues);
    if (issueNumber) {
      createdIssues.set(issue.id, issueNumber);
    }

    // Small delay to avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  // Step 3: Summary
  console.log('\n' + '='.repeat(50));
  console.log('Summary:');
  console.log(`  Total issues created: ${createdIssues.size} / ${config.issues.length}`);
  console.log('\nIssue mapping:');
  Array.from(createdIssues.entries())
    .sort((a, b) => a[0] - b[0])
    .forEach(([localId, ghNumber]) => {
      const issue = config.issues.find(i => i.id === localId);
      console.log(`  Issue ${localId} -> #${ghNumber}: ${issue.title}`);
    });

  console.log('\nDone! View all issues:');
  console.log('  gh issue list --limit 20');
}

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
