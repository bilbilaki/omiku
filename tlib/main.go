package main

/*
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
// Mocking Dart Native API types so Go can compile without the actual header file
typedef int64_t Dart_Port;

typedef enum {
    Dart_CObject_kNull = 0,
    Dart_CObject_kBool,
    Dart_CObject_kInt32,
    Dart_CObject_kInt64,
    Dart_CObject_kDouble,
    Dart_CObject_kString,
    Dart_CObject_kArray,
    Dart_CObject_kTypedData,
    Dart_CObject_kExternalTypedData,
    Dart_CObject_kUnsupported,
    Dart_CObject_kNumberOfTypes
} Dart_CObject_Type;

typedef struct _Dart_CObject {
    Dart_CObject_Type type;
    union {
        bool as_bool;
        int32_t as_int32;
        int64_t as_int64;
        double as_double;
        char* as_string;
    } value;
} Dart_CObject;

// This function pointer will hold the pointer to Dart_PostCObject
typedef bool (*Dart_PostCObject_Type)(Dart_Port port_id, Dart_CObject* message);

static bool CallDartPostCObject(Dart_PostCObject_Type fp, Dart_Port port_id, Dart_CObject* message) {
    return fp(port_id, message);
}
*/
import "C"
import (
	"archive/zip"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"unsafe"

	"github.com/fluxcd/pkg/tar"
	"github.com/gen2brain/go-fitz"
	"github.com/gen2brain/go-unarr"
	"github.com/ninehills/pdf2md/pkg/pdf"
)

var dartPostCObject C.Dart_PostCObject_Type

//export InitializeDartAPI
func InitializeDartAPI(apiPointer C.Dart_PostCObject_Type) {
	dartPostCObject = apiPointer
}

func decomp(a *unarr.Archive, t string) error {
	_, err := a.Extract(t)
	if err != nil {
		return err
	}
	return nil
}

func ExtractCBZ(source string, targetDir string) error {
	reader, err := zip.OpenReader(source)
	if err != nil {
		return fmt.Errorf("failed to open cbz: %w", err)
	}
	defer reader.Close()

	if err := os.MkdirAll(targetDir, 0755); err != nil {
		return fmt.Errorf("failed to create target directory: %w", err)
	}

	for _, file := range reader.File {
		extractedFilePath := filepath.Join(targetDir, file.Name)
		if !strings.HasPrefix(extractedFilePath, filepath.Clean(targetDir)+string(os.PathSeparator)) {
			return fmt.Errorf("illegal file path in archive: %s", file.Name)
		}

		if file.FileInfo().IsDir() {
			os.MkdirAll(extractedFilePath, file.Mode())
			continue
		}

		if err := os.MkdirAll(filepath.Dir(extractedFilePath), 0755); err != nil {
			return err
		}

		archiveFile, err := file.Open()
		if err != nil {
			return err
		}

		destinationFile, err := os.OpenFile(extractedFilePath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, file.Mode())
		if err != nil {
			archiveFile.Close()
			return err
		}

		_, err = io.Copy(destinationFile, archiveFile)
		archiveFile.Close()
		destinationFile.Close()

		if err != nil {
			return fmt.Errorf("failed to extract file %s: %w", file.Name, err)
		}
	}
	return nil
}

func epub(fp, tp string) ([]string, error) {
	var epath []string
	nd, err := fitz.New(fp)
	if err != nil {
		return epath, err
	}
	defer nd.Close()

	ni := nd.NumPage()
	err = os.MkdirAll(tp, 0755)
	if err != nil {
		return epath, err
	}

	for l := 0; l < ni; l++ {
		png, err := nd.ImagePNG(l, 100)
		if err != nil {
			return epath, err
		}
		f := fmt.Sprintf("%s/%s.png", tp, strconv.Itoa(l))
		ff, err := os.Create(f)
		if err != nil {
			return epath, err
		}
		_, err = ff.Write(png)
		ff.Close() // Ensure close inside the loop
		if err != nil {
			return epath, err
		}
		epath = append(epath, f)
	}
	return epath, nil
}

func crewler(p, t string) error {
	f, err := os.Open(p)
	if err != nil {
		return err
	}
	defer f.Close()

	if err := tar.Untar(f, t, tar.WithSkipGzip(), tar.WithMaxUntarSize(5000<<20)); err != nil {
		return err
	}
	return nil
}

//export StartExtraction
func StartExtraction(port C.Dart_Port, archivePath, pPath *C.char) {
	// Convert C strings to Go strings safely BEFORE launching the asynchronous goroutine
	goPath := C.GoString(archivePath)
	goPPath := C.GoString(pPath)

	go func(p, pp string) {
		sendLog(port, "extracting task started...")

		// Clean up and define primary target output folder
		baseName := filepath.Base(p)
		pn := filepath.Join(pp, baseName+"-extracted")

		err := os.MkdirAll(pn, 0755)
		if err != nil {
			sendLog(port, "failed to create base directory: "+err.Error())
			return
		}
		tmpDir := pn
		ext := strings.ToLower(filepath.Ext(p))

		switch ext {
		case ".pdf":
			doc, err := pdf.ExtractPages(p, 100, tmpDir)
			if err != nil {
				sendLog(port, err.Error())
				return
			}
			sendLog(port, fmt.Sprintf("extracted images: %s", fmt.Sprint(doc)))

		case ".epub":
			doc, err := epub(p, tmpDir)
			if err != nil {
				sendLog(port, err.Error())
				return
			}
			sendLog(port, fmt.Sprintf("extracted images: %s", fmt.Sprint(doc)))

		case ".cbz":
			err := ExtractCBZ(p, tmpDir)
			if err != nil {
				sendLog(port, err.Error())
				return
			}
			sendLog(port, fmt.Sprintf("extracted images: %s", tmpDir))

		default: // Multi-file archive container format (Zip, Tar, Rar, 7z)
			if ext == ".tar" {
				sendLog(port, "tar archive detected start processing...")
				err := crewler(p, tmpDir)
				if err != nil {
					sendLog(port, err.Error())
					return
				}
			} else if ext == ".zip" || ext == ".7z" || ext == ".rar" {
				sendLog(port, "archive file detected starting extracting that first...")
				a, err := unarr.NewArchive(p)
				if err != nil {
					sendLog(port, err.Error())
					return
				}
				err = decomp(a, tmpDir)
				if err != nil {
					sendLog(port, err.Error())
					return
				}
			}

			// Scan container directory for internal files
			var pdfs []string
			var epubs []string
			sendLog(port, "extracting archive done. finding media files...")

			err = filepath.WalkDir(tmpDir, func(path string, d fs.DirEntry, err error) error {
				if err != nil || d.IsDir() {
					return err
				}
				innerExt := strings.ToLower(filepath.Ext(path))
				if innerExt == ".pdf" {
					pdfs = append(pdfs, path)
					sendLog(port, fmt.Sprintf("add pdf file: %s ", filepath.Base(path)))
				} else if innerExt == ".epub" {
					epubs = append(epubs, path)
					sendLog(port, fmt.Sprintf("add epub file: %s ", filepath.Base(path)))
				}
				return nil
			})
			if err != nil {
				sendLog(port, err.Error())
				return
			}

			// Process found nested PDF books
			if len(pdfs) != 0 {
				pdfParentDir := filepath.Join(tmpDir, "extracted-pdfs")
				os.MkdirAll(pdfParentDir, 0755)

				for l := 0; l < len(pdfs); l++ {
					targetFile := pdfs[l]
					bookFolder := filepath.Join(pdfParentDir, filepath.Base(targetFile)+"-extracted")
					os.MkdirAll(bookFolder, 0755)

					sendLog(port, fmt.Sprintf("extracting %s to directory %s...", filepath.Base(targetFile), bookFolder))
					doc, err := pdf.ExtractPages(targetFile, 100, bookFolder)
					if err != nil {
						sendLog(port, err.Error())
						continue
					}
					sendLog(port, fmt.Sprintf("extracted pdf images to: %s", fmt.Sprint(doc)))
				}
			}

			// Process found nested EPUB books (Fixed: placed outside the PDF conditional block)
			if len(epubs) != 0 {
				epubParentDir := filepath.Join(tmpDir, "extracted-epubs")
				os.MkdirAll(epubParentDir, 0755)

				for l := 0; l < len(epubs); l++ {
					targetFile := epubs[l]
					bookFolder := filepath.Join(epubParentDir, filepath.Base(targetFile)+"-extracted")
					os.MkdirAll(bookFolder, 0755)

					sendLog(port, fmt.Sprintf("extracting %s to directory %s...", filepath.Base(targetFile), bookFolder))
					doc, err := epub(targetFile, bookFolder)
					if err != nil {
						sendLog(port, err.Error())
						continue
					}
					sendLog(port, fmt.Sprintf("extracted epub images to: %s", fmt.Sprint(doc)))
				}
			}
		}
	}(goPath, goPPath)
}

func sendLog(port C.Dart_Port, message string) {
	if dartPostCObject == nil {
		return
	}
	var cobj C.Dart_CObject
	cobj._type = C.Dart_CObject_kString
	cStr := C.CString(message)
	*(*[8]byte)(unsafe.Pointer(&cobj.value)) = *(*[8]byte)(unsafe.Pointer(&cStr))
	C.CallDartPostCObject(dartPostCObject, port, &cobj)
	C.free(unsafe.Pointer(cStr))
}

func main() {}