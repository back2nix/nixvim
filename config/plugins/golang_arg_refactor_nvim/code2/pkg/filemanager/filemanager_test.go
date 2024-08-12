package filemanager

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"
)

func TestFileManager(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "filemanager_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	fm := NewFileManager()

	t.Run("ReadFile", func(t *testing.T) {
		content := []byte("test content")
		filePath := filepath.Join(tempDir, "test.txt")
		err := ioutil.WriteFile(filePath, content, 0o644)
		if err != nil {
			t.Fatalf("Failed to write test file: %v", err)
		}

		readContent, err := fm.ReadFile(filePath)
		if err != nil {
			t.Fatalf("ReadFile failed: %v", err)
		}
		if string(readContent) != string(content) {
			t.Errorf("ReadFile content mismatch. Got %s, want %s", string(readContent), string(content))
		}

		_, err = fm.ReadFile("non_existent_file.txt")
		if err == nil {
			t.Error("ReadFile should fail for non-existent file")
		}
	})

	t.Run("WriteFile", func(t *testing.T) {
		content := []byte("new content")
		filePath := filepath.Join(tempDir, "write_test.txt")

		err := fm.WriteFile(filePath, content)
		if err != nil {
			t.Fatalf("WriteFile failed: %v", err)
		}

		readContent, err := ioutil.ReadFile(filePath)
		if err != nil {
			t.Fatalf("Failed to read written file: %v", err)
		}
		if string(readContent) != string(content) {
			t.Errorf("WriteFile content mismatch. Got %s, want %s", string(readContent), string(content))
		}
	})

	t.Run("CreateFile", func(t *testing.T) {
		content := []byte("created content")
		filePath := filepath.Join(tempDir, "create_test.txt")

		err := fm.CreateFile(filePath, content)
		if err != nil {
			t.Fatalf("CreateFile failed: %v", err)
		}

		readContent, err := ioutil.ReadFile(filePath)
		if err != nil {
			t.Fatalf("Failed to read created file: %v", err)
		}
		if string(readContent) != string(content) {
			t.Errorf("CreateFile content mismatch. Got %s, want %s", string(readContent), string(content))
		}

		err = fm.CreateFile(filePath, content)
		if err == nil {
			t.Error("CreateFile should fail for existing file")
		}
	})

	t.Run("FileExists", func(t *testing.T) {
		existingFile := filepath.Join(tempDir, "existing.txt")
		err := ioutil.WriteFile(existingFile, []byte(""), 0o644)
		if err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}

		if !fm.FileExists(existingFile) {
			t.Error("FileExists should return true for existing file")
		}

		if fm.FileExists("non_existent_file.txt") {
			t.Error("FileExists should return false for non-existent file")
		}
	})

	t.Run("GetGoFiles", func(t *testing.T) {
		goFile1 := filepath.Join(tempDir, "file1.go")
		goFile2 := filepath.Join(tempDir, "file2.go")
		nonGoFile := filepath.Join(tempDir, "file.txt")

		files := []string{goFile1, goFile2, nonGoFile}
		for _, file := range files {
			err := ioutil.WriteFile(file, []byte(""), 0o644)
			if err != nil {
				t.Fatalf("Failed to create test file: %v", err)
			}
		}

		goFiles, err := fm.GetGoFiles(tempDir)
		if err != nil {
			t.Fatalf("GetGoFiles failed: %v", err)
		}

		if len(goFiles) != 2 {
			t.Errorf("GetGoFiles returned wrong number of files. Got %d, want 2", len(goFiles))
		}

		for _, file := range goFiles {
			if filepath.Ext(file) != ".go" {
				t.Errorf("GetGoFiles returned non-Go file: %s", file)
			}
		}
	})
}
