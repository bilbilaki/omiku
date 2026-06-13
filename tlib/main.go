package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
"github.com/gen2brain/go-unarr"
	"github.com/fluxcd/pkg/tar"
	"github.com/ninehills/pdf2md/pkg/pdf"
)
func decomp(a *unarr.Archive, t string)error{
_, err:=  a.Extract(t)
if err!=nil{
	return err
}
return nil
}
func crewler(p,t string)error{

	f, err := os.Open(p)
if err != nil {
	return err
}
defer f.Close()

if err := tar.Untar(f, t, tar.WithSkipGzip() ,tar.WithMaxUntarSize(5000<<20) ); err != nil {
	return err
}
return  nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("add path to a pdf file like ./tlib $pdf_file_path")
		return
	}
p:= os.Args[len(os.Args)-1]
pn := filepath.Base(p)+"-extracted"
var	tmpDir string
var pdfs []string
var pnn string
	 err := os.Mkdir(pn,0755)
	if err != nil {
		panic(err)
	}
	tmpDir =string(fmt.Sprintf("./%s",pn))
if strings.Contains(filepath.Ext(p),"tar"){
  err:=	crewler(p,tmpDir)
  if err !=nil{
	fmt.Println(err)
	return
  }else if strings.Contains(filepath.Ext(p),"zip")||strings.Contains(filepath.Ext(p),"7z")||strings.Contains(filepath.Ext(p),"rar"){
a,err:=	unarr.NewArchive(p)
if err!=nil{
	fmt.Println(err)
	return
}
err = decomp(a,tmpDir)
if err!= nil{
	fmt.Println(err)
}
  }
 err= filepath.WalkDir(tmpDir,func(path string, d fs.DirEntry, err error) error {
if d.IsDir(){
	return err
}
ex := filepath.Ext(path)
if strings.Contains(ex,"pdf"){
	pdfs = append(pdfs, path)
	return err
}
return err	
  })
if err!=nil{
	fmt.Println(err)
	return
}
err = os.Mkdir(fmt.Sprintf("%s/extracted-pdfs",tmpDir),0755)
if err!=nil {
	fmt.Println(err)
	return
}
dd:=tmpDir
for l := 0 ; l <len(pdfs); l++{
	i := pdfs[l]
	pnn = filepath.Base(i)+"-extracted"
err = os.Mkdir(fmt.Sprintf("%s/extracted-pdfs/%s",tmpDir,pnn),0755)

		tmpDir =string(fmt.Sprintf("%s/extracted-pdfs/%s",dd,pnn))


doc, err := pdf.ExtractPages(i,100,tmpDir)
	if err != nil {
		panic(err)
	}
	fmt.Println(doc)
	
}
}else{

	doc, err := pdf.ExtractPages(p,100,tmpDir)
	if err != nil {
		panic(err)
	}
	fmt.Println(doc)
}
}
