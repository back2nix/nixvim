package filemanager

import (
	"io/ioutil"
	"os"
	"path/filepath"
)

type FileManager struct{}

func NewFileManager() *FileManager {
	return &FileManager{}
}

func (fm *FileManager) ReadFile(filePath string) ([]byte, error) {
	return ioutil.ReadFile(filePath)
}

func (fm *FileManager) WriteFile(filePath string, content []byte) error {
	return ioutil.WriteFile(filePath, content, 0o644)
}

func (fm *FileManager) CreateFile(filePath string, content []byte) error {
	if fm.FileExists(filePath) {
		return os.ErrExist
	}
	return fm.WriteFile(filePath, content)
}

func (fm *FileManager) FileExists(filePath string) bool {
	_, err := os.Stat(filePath)
	return !os.IsNotExist(err)
}

func (fm *FileManager) GetGoFiles(dirPath string) ([]string, error) {
	var goFiles []string
	err := filepath.Walk(dirPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && filepath.Ext(path) == ".go" {
			goFiles = append(goFiles, path)
		}
		return nil
	})
	return goFiles, err
}
