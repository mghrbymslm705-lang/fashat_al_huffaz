import fitz
doc = fitz.open('C:/Users/mj/Desktop/%D9%85%D8%B3%D8%A7%D8%A8%D9%82%D8%A7%D8%AA-%D8%AD%D9%84%D9%82%D8%A7%D8%AA-%D8%A7%D9%84%D8%AA%D8%AD%D9%81%D9%8A%D8%B8.pdf')
print(f'Pages: {doc.page_count}')
for i in range(min(doc.page_count, 3)):
    text = doc[i].get_text()
    print(f'--- Page {i+1} ---')
    print(text[:500] if text else 'No text')
doc.close()