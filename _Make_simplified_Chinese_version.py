from os import path as os_path
from zhconv import convert


def conver_file(source_file, source_code, dest_file, dest_code):
    try:
        with open(source_file, 'r', encoding=source_code) as f:
            _ = f.read()
        _ = convert(_, 'zh-hans')
        with open(dest_file, 'w', encoding=dest_code) as f:
            f.write(_)
    except Exception as e:
        print(f'error: {e}')
    else:
        print('Done')


if __name__ == '__main__':
    work_path = os_path.split(os_path.realpath(__file__))[0]
    input_file = os_path.join(work_path, 'change_prot_of_RDP_tw.bat')
    output_file = os_path.join(work_path, 'change_prot_of_RDP_cn.bat')
    conver_file(input_file, 'big5', output_file, 'gbk')
    input('\n請按回車鍵退出...')
