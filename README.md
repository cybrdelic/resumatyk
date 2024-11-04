# Resumatyk

Resumatyk is a powerful command-line tool for managing LaTeX resumes with AI-powered variant generation. It enables easy creation, editing, and management of multiple resume versions while leveraging Claude AI to generate creative, themed variants.

## Features

- 📝 LaTeX Resume Management
  - Create and edit resumes using your preferred editor (micro)
  - Compile with XeLaTeX support
  - View PDFs with zathura
  - Clean auxiliary files

- 🎨 AI-Powered Variant Generation
  - Generate unique resume designs using Claude AI
  - Customize themes and styles
  - Support for multiple fonts and layouts
  - Automatic error correction and compilation

- 📧 Email Integration
  - Send resumes directly via Gmail SMTP
  - Attachment support with proper MIME handling
  - Configurable email templates

- 🔍 Smart Content Extraction
  - OCR support for existing PDFs
  - Intelligent structure preservation
  - Clean formatting of extracted content

## Prerequisites

- XeLaTeX
- Python 3.x
- curl
- jq
- micro (text editor)
- zathura (PDF viewer)
- tesseract-ocr
- poppler-utils

For OCR functionality:
```bash
sudo apt-get install poppler-utils tesseract-ocr tesseract-ocr-eng
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/resumatyk.git
cd resumatyk
```

2. Set up the directory structure:
```bash
mkdir -p ~/.local/share/resumatyk/{lib,bin}
```

3. Copy files to their locations:
```bash
cp lib/* ~/.local/share/resumatyk/lib/
cp bin/resume ~/.local/share/resumatyk/bin/
chmod +x ~/.local/share/resumatyk/bin/resume
```

4. Add the binary to your PATH in `~/.bashrc` or `~/.zshrc`:
```bash
export PATH="$HOME/.local/share/resumatyk/bin:$PATH"
```

5. Configure environment variables in `~/.zshrc` or `~/.bashrc`:
```bash
export ANTHROPIC_API_KEY="your_claude_api_key"
export SMTP_USER="your_gmail@gmail.com"
export SMTP_PASS="your_app_specific_password"
```

## Usage

### Interactive Mode

Launch the interactive interface:
```bash
resume
```

### Command Line Interface

```bash
resume [command]

Commands:
    list        List all resumes
    edit        Select and edit a resume
    compile     Select and compile a resume
    view        Select and view a PDF
    email       Select and email a resume
    variant     Manage resume variants
    clean       Clean auxiliary files
    help        Show help message
    version     Show version information
```

### Managing Variants

1. Select a base resume
2. Choose "Manage Variants"
3. Options:
   - List existing variants
   - Create new variant
   - Edit variant
   - View variant PDF
   - Send variant via email

When creating a new variant, you'll be prompted to:
1. Enter a variant name
2. Provide theme preferences
3. Choose styling options:
   - Color scheme
   - Layout style
   - Typography
   - Additional design elements

## Directory Structure

```
~/.local/share/resumatyk/
├── lib/
│   ├── config.sh
│   ├── content_extractor.sh
│   ├── email.sh
│   ├── finder.sh
│   ├── logger.sh
│   ├── resume_manager.sh
│   ├── selector.sh
│   ├── utils.sh
│   ├── validator.sh
│   └── variant_generator.sh
└── bin/
    └── resume
```

Your resumes are stored in:
```
~/resumes/
├── your_resume.tex
├── your_resume.pdf
└── variants/
    └── your_resume/
        ├── variant1.tex
        └── variant1.pdf
```

## Configuration

Default settings in `config.sh`:
- `RESUME_DIR`: Location of resume files (`$HOME/resumes`)
- `EMAIL_TO`: Default recipient email
- `EMAIL_SUBJECT`: Default email subject
- `EMAIL_BODY`: Default email body text
- `MAX_DEPTH`: Maximum directory search depth

## Logging

The tool includes rich logging with:
- Timestamps
- Color-coded messages
- Progress indicators
- Error tracking
- Debug information

## Error Handling

- Automatic retry for failed compilations
- Detailed error messages
- LaTeX compilation validation
- Font compatibility checks
- Package dependency verification

## Contributing

Contributions are welcome! Please feel free to submit pull requests or create issues for bugs and feature requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Claude AI for variant generation
- LaTeX for document processing
- Various open-source tools and libraries used in the project
