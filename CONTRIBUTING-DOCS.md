# Contributing to SyntaxKit

**Help us make Swift code generation more accessible!** SyntaxKit is a community-driven project that thrives on contributions from developers like you.

## 🚀 Quick Start for Contributors

### What Can You Contribute?

**🎯 High-Impact Areas:**
- **Examples & Tutorials**: Show real-world SyntaxKit usage
- **Documentation**: Improve clarity and add missing explanations  
- **Bug Fixes**: Help us squash issues and improve reliability
- **New Features**: Extend SyntaxKit's capabilities

**💡 Perfect First Contributions:**
- Add a new example to `/Examples/Completed/`
- Fix a typo or improve documentation clarity
- Add tests for existing functionality
- Improve error messages or user experience

### 🛠️ Development Setup (2 minutes)

```bash
# Clone and set up
git clone https://github.com/brightdigit/SyntaxKit.git
cd SyntaxKit

# Verify everything works
swift build && swift test
```

### 📝 Making Your First Contribution

1. **Find an Issue**: Check [GitHub Issues](https://github.com/brightdigit/SyntaxKit/issues) for "good first issue" labels
2. **Fork & Branch**: Create a feature branch from `main`
3. **Make Changes**: Keep changes focused and testable
4. **Test**: Run `swift build && swift test` to ensure nothing breaks
5. **Submit PR**: Include a clear description of what you changed and why

## 📚 Documentation Contributions

**We especially need help with:**
- **Tutorials**: Step-by-step guides for common use cases
- **Examples**: Real-world code generation scenarios
- **API Docs**: Clear explanations with working examples

**Quality Standards (Simple):**
- ✅ Code examples compile and run
- ✅ Clear, helpful explanations
- ✅ Test your changes locally

**Automated Validation:**
- Run `./Scripts/validate-docs.sh` to validate all documentation
- Use `./Scripts/validate-docs.sh --file path/to/file.md` for specific files
- All documentation changes are automatically tested in CI/CD

## 🎨 Example Contributions

**Add a New Example:**
```bash
# Create a new example directory
mkdir Examples/Completed/your_example
cd Examples/Completed/your_example

# Add your example files
touch code.swift dsl.swift syntax.json
```

**Example Structure:**
- `code.swift`: The generated Swift code
- `dsl.swift`: The SyntaxKit code that generates it
- `syntax.json`: Optional metadata

## 🤝 Community Guidelines

- **Be Respectful**: We're all here to learn and help
- **Ask Questions**: Use GitHub Discussions for help
- **Share Ideas**: Propose new features or improvements
- **Help Others**: Answer questions and review PRs

## 🏆 Recognition

Contributors are recognized in:
- Release notes for significant contributions
- README acknowledgments
- GitHub contributor graphs
- Community showcases

## 📞 Need Help?

- **Questions**: [GitHub Discussions](https://github.com/brightdigit/SyntaxKit/discussions)
- **Bugs**: [GitHub Issues](https://github.com/brightdigit/SyntaxKit/issues)
- **Ideas**: Open a discussion or issue

---

**Ready to contribute?** Pick an issue, make a small change, and submit your first PR! Every contribution, no matter how small, makes SyntaxKit better for everyone. 🎉