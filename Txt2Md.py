import re
import os


class Converter:
    def __init__(self):
        self.paragraph_tab_num = 0
        self.table_head_flag = 1
        self.table_column = 0
        self.table_right_row = 0

    def convertTitle(self, content):
        prefix = re.findall(r"(.*?)\d+\.", content)[0]
        tab_num = prefix.count("\t") + 1
        content = content.replace(prefix, "")
        content = "#" * tab_num + " " + content
        self.paragraph_tab_num = 0
        self.table_head_flag = 1
        return content

    def convertParagraph(self, content):
        try:
            tab_num = re.findall(r"\t*\t", content)[0].count("\t")
        except Exception as e:
            print(e)
            print(content)
            os.system("pause")
            tab_num = 0
        self.paragraph_tab_num = tab_num if self.paragraph_tab_num == 0 else self.paragraph_tab_num
        space_num = (tab_num - self.paragraph_tab_num + 1) * 4
        content = re.sub(r"\t*\t", " " * space_num, content, count=1, flags=0)
        self.table_head_flag = 1
        return content

    def convertTable(self, content, md_file):
        """
        表格样式1: - ... #...
        表格样式2: - ...
                    ...
        表格样式3: - ...
                    #...#
                    #...#
                    #...
        """
        if self.table_head_flag == 1:
            # 添加表头
            md_file.write("| 参数 | 描述 |\n")
            md_file.write("| --- | --- |\n")
            self.table_head_flag = 0
        if self.table_column == 0:
            content = re.sub(r"\t*- ", "| ", content)
            if "#" in content:
                # 表格样式1左右列
                content = content.replace("  #", " | ")
                self.table_column = 0
                return content
            else:
                # 表格样式2,3的左列
                content = content[:-1] + " | "
                self.table_column = 1
        else:
            # 表格样式2,3的右列
            content = re.sub(r"\t+#+ *", "", content)
            if content[-2] == "#":
                content = content[:-2] + "<br>"
                self.table_column = 1
            else:
                self.table_column = 0
        return content


def txtToMd(txt_file_path):
    md_file_path = txt_file_path.replace("Txt", "Markdown").split(".")[0] + ".md"
    txt_file = open(txt_file_path, "r", encoding="utf8")
    md_file = open(md_file_path, "w", encoding="utf8")
    converter1 = Converter()
    for content in txt_file.readlines():
        if content == "\n":
            continue
        elif re.match(r"\t*\d+\.\S", content):
            content = converter1.convertTitle(content)
        elif re.match(r"\t*- ", content) or converter1.table_column == 1:
            content = converter1.convertTable(content, md_file)
        else:
            content = converter1.convertParagraph(content)
        md_file.write(content)
    txt_file.close()
    md_file.close()


txt_file_prefix = "D:/Code/笔记/Txt/"
txt_file_list = [
    "JavaSE.txt",
    "Linux.txt",
    "Hadoop.txt",
    "Hive.txt",
    "Flume.txt",
    "Kafka.txt",
    "Maxwell&DataX.txt",
    "采集项目.txt",
    "Spark.txt",
    "数据仓库.txt",
    "Redis.txt",
    "Flink.txt",
]

for txt_file_path in txt_file_list:
    txtToMd(txt_file_prefix + txt_file_path)
