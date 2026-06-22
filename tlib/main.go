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
	"regexp"
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
//export UnarchiveN
func UnarchiveN(port C.Dart_Port,filePath , targetPath *C.char){
	goFilePath := C.GoString(filePath)
	goTargetPath := C.GoString(targetPath)
arch,err:=	unarr.NewArchive(goFilePath)
if err!=nil{
	sendLog(port,err.Error())
	return;

}

	go func(a *unarr.Archive, tpath string) {
		err:= Unarchive(a ,tpath )
		if err != nil {
			sendLog(port, err.Error())
			return;

		}
		sendLog(port,"finish")
		return;
	}(arch, goTargetPath)
}

func Unarchive(a *unarr.Archive, t string) error {
	_, err := a.Extract(t)
	if err != nil {
		return err
	}
	return nil
}
//export UncbzN
func UncbzN(port C.Dart_Port, filePath , targetPath *C.char){
	goFilePath := C.GoString(filePath)
	goTargetPath := C.GoString(targetPath)
	go func(path,tpath string) {
		err := Uncbz(path,tpath)
		if err != nil {
			sendLog(port,err.Error())
			return;
		}
		sendLog(port,"finish")
		return;
	}(goFilePath,goTargetPath)

}
func Uncbz(source string, targetDir string) error {
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
//export UnepubN
func UnepubN(port C.Dart_Port, filePath,targetPath *C.char){
	goFilePath := C.GoString(filePath)
	goTargetPath := C.GoString(targetPath)

	go func(path, tpath string) {
		err:=Unepub(path,tpath)
		if err != nil {
			sendLog(port , "failed to unepub files: "+path+" "+tpath)
			return;
		}
		sendLog(port,"finish")
		return;
	}(goFilePath, goTargetPath)
}
func Unepub(fp, tp string) error {
	var epath []string
	nd, err := fitz.New(fp)
	if err != nil {
		return err
	}
	defer nd.Close()

	ni := nd.NumPage()
	err = os.MkdirAll(tp, 0755)
	if err != nil {
		return err
	}

	for l := 0; l < ni; l++ {
		png, err := nd.ImagePNG(l, 100)
		if err != nil {
			return err
		}
		f := fmt.Sprintf("%s/%s.png", tp, strconv.Itoa(l))
		ff, err := os.Create(f)
		if err != nil {
			return err
		}
		_, err = ff.Write(png)
		ff.Close() // Ensure close inside the loop
		if err != nil {
			return err
		}
		epath = append(epath, f)
	}
	return nil
}
//export UnpdfN
func UnpdfN(port C.Dart_Port,filePath , targetPath *C.char){
	goFilePath := C.GoString(filePath)
	goTargetPath := C.GoString(targetPath)
	go func(path,targetpath string) {
		err:= Unpdf(path,targetpath)
		if err != nil {
			sendLog(port, fmt.Sprintf("failed to extract Pdf: %s", err))
			return;
		}
		sendLog(port,"finish")
	}(goFilePath,goTargetPath)

}
func Unpdf(p, t string) error {
	_, err := pdf.ExtractPages(p, 100, t)
	if err != nil {
		return err
	}
	return nil

}
//export UntarN
func UntarN(port C.Dart_Port , filePath , targetPath *C.char){
	goFilePath := C.GoString(filePath)
	goTargetPath := C.GoString(targetPath)

	go func(path,tpath string) {
	err:=	Untar(path, tpath)
	if err != nil {
		sendLog(port, fmt.Sprintf("failed to untar %s: %s", path, err.Error()))
		return;
	}
	sendLog(port,"finish")
	}(goFilePath, goTargetPath)

}
func Untar(p, t string) error {
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
func ExtractChapterNumber(filename string) (string, bool) {
	// Pattern breakdown:
	// (?i)             -> Case-insensitive flag (matches ch, CH, Chapter, CHAPTER)
	// \b(ch|chapter)\b -> Matches the word "ch" or "chapter" as a distinct word token
	// [[:space:]*-_]* -> Matches any optional spaces, asterisks, hyphens, or underscores
	// ([0-9]+)         -> Captures the actual chapter number (one or more digits)
	re := regexp.MustCompile(`(?i)\b(ch|chapter)\b[[:space:]*-_]*([0-9]+)`)

	matches := re.FindStringSubmatch(filename)

	// matches[0] is the whole matched string
	// matches[1] is the prefix (ch/chapter)
	// matches[2] is our target capture group (the number)
	if len(matches) > 2 {
		return matches[2], true
	}

	return "", false
}

//export StartExtractionSeriesArchive
func StartExtractionSeriesArchive(port C.Dart_Port, archivePath, pPath, seriesId *C.char) {
	goPath := C.GoString(archivePath)
	goPPath := C.GoString(pPath)
	goId := C.GoString(seriesId)

	go func(p, pp, id string) {
		sendLog(port, "extracting task started...")

		// Clean up and define primary target output folder

		pn := filepath.Join(pp, id)

		err := os.MkdirAll(pn, 0755)
		if err != nil {
			sendLog(port, "failed to create base directory: "+err.Error())
			return
		}
		tmpDir := pn
		ext := strings.ToLower(filepath.Ext(p))

		switch ext {
		case ".tar":
			sendLog(port, "tar archive detected start processing...")
			err := Untar(p, tmpDir)
			if err != nil {
				sendLog(port, err.Error())
				return
			}

		default:
			sendLog(port, "archive file detected starting extracting that first...")
			a, err := unarr.NewArchive(p)
			if err != nil {
				sendLog(port, err.Error())
				return
			}
			err = Unarchive(a, tmpDir)
			if err != nil {
				sendLog(port, err.Error())
				return
			}

			// Scan container directory for internal files
			var pdfs []string
			var epubs []string
			var cbzs []string
			sendLog(port, "extracting archive done. finding media files...")

			err = filepath.WalkDir(tmpDir, func(path string, d fs.DirEntry, err error) error {
				if err != nil || d.IsDir() {
					return err
				}
				innerExt := strings.ToLower(filepath.Ext(path))
				switch innerExt {
				case ".pdf":
					pdfs = append(pdfs, path)
					sendLog(port, fmt.Sprintf("add pdf file: %s ", filepath.Base(path)))
				case ".epub":
					epubs = append(epubs, path)
					sendLog(port, fmt.Sprintf("add epub file: %s ", filepath.Base(path)))
				case ".cbz":
					cbzs = append(cbzs, path)
					sendLog(port, fmt.Sprintf("add cbz file: %s ", filepath.Base(path)))
				}
				return nil
			})
			if err != nil {
				sendLog(port, err.Error())
				return
			}

			// Process found nested PDF books
			if len(pdfs) != 0 {
				for l := 0; l < len(pdfs); l++ {
					targetFile := pdfs[l]
					detectedChap, b := ExtractChapterNumber(targetFile)
					if b == false {
						detectedChap = fmt.Sprintf("unrecogonizedChapNum-%s", filepath.Base(targetFile))
					}

					bookFolder := filepath.Join(tmpDir, fmt.Sprintf("chapter-%s", detectedChap))
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

				for l := 0; l < len(epubs); l++ {
					targetFile := epubs[l]

					detectedChap, b := ExtractChapterNumber(targetFile)
					if b == false {
						detectedChap = fmt.Sprintf("unrecogonizedChapNum-%s", filepath.Base(targetFile))
					}

					bookFolder := filepath.Join(tmpDir, fmt.Sprintf("chapter-%s", detectedChap))
					os.MkdirAll(bookFolder, 0755)

					sendLog(port, fmt.Sprintf("extracting %s to directory %s...", filepath.Base(targetFile), bookFolder))
					err := Unepub(targetFile, bookFolder)
					if err != nil {
						sendLog(port, err.Error())
						continue
					}
					sendLog(port, fmt.Sprintf("extracted epub from: %s", targetFile))
				}
			}
			if len(cbzs) != 0 {

				for l := 0; l < len(cbzs); l++ {
					targetFile := cbzs[l]

					detectedChap, b := ExtractChapterNumber(targetFile)
					if b == false {
						detectedChap = fmt.Sprintf("unrecogonizedChapNum-%s", filepath.Base(targetFile))
					}

					bookFolder := filepath.Join(tmpDir, fmt.Sprintf("chapter-%s", detectedChap))
					os.MkdirAll(bookFolder, 0755)

					sendLog(port, fmt.Sprintf("extracting %s to directory %s...", filepath.Base(targetFile), bookFolder))
					err := Uncbz(targetFile, bookFolder)
					if err != nil {
						sendLog(port, err.Error())
						continue
					}
					sendLog(port, fmt.Sprintf("extracted cbz from: %s", targetFile))
				}
			}
		}
		sendLog(port, "finish")
	}(goPath, goPPath, goId)
}

//export StartExtractionChapter
func StartExtractionChapter(port C.Dart_Port, filePathC, pPath, seriesId *C.char, chapterNumber *C.int) {
	goPath := C.GoString(filePathC)
	goPPath := C.GoString(pPath)
	goSeriesId := C.GoString(seriesId)
	cahpnum := int(*chapterNumber)
	go func(p, pp, seriesid string, chapnum int) {
		sendLog(port, "extracting task started...")

		// Clean up and define primary target output folder

		pn := filepath.Join(pp, seriesid, fmt.Sprintf("chapter-%d", chapnum))
		err := os.MkdirAll(pn, 0755)
		if err != nil {
			sendLog(port, "failed to create base directory: "+err.Error())
			return
		}
		tmpDir := pn
		ext := strings.ToLower(filepath.Ext(p))

		switch ext {
		case ".pdf":
			err := Unpdf(p, tmpDir)
			if err != nil {
				sendLog(port, err.Error())
				return
			}
			sendLog(port, fmt.Sprintf("extracted images from %s to %s", p, tmpDir))

		case ".epub":
			err := Unepub(p, tmpDir)
			if err != nil {
				sendLog(port, err.Error())
				return
			}
			sendLog(port, fmt.Sprintf("extracted images from %s to %s", p, tmpDir))

		case ".cbz":
			err := Uncbz(p, tmpDir)
			if err != nil {
				sendLog(port, err.Error())
				return
			}
			sendLog(port, fmt.Sprintf("extracted images from %s to %s", p, tmpDir))

		}
		sendLog(port, "finish")
	}(goPath, goPPath, goSeriesId, cahpnum)
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
