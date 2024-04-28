import csv

def convert_src(in_filepath: str, out_filepath: str) -> None:
    output_dat = list()
    with open(in_filepath, mode="rt", encoding="utf8") as f:
        csv_data = [line for line in csv.reader(f)]
        dim_1_area = csv_data[2][1:]
        dim_2_area = csv_data[3][1:]
        dim_3_type = csv_data[4][1:]
        dim_4_type = [(item if item else "計測値") for item in csv_data[6]][1:]
        contents = csv_data[7:]

        # 横持ちで格納されている地域 (dim_1_area - dim_2_area) を縦持ちに変更する
        for in_record in contents:
            ymd_val = in_record[0]
            out_record = dict()
            current_dim = None
            for dim_val in zip(dim_1_area, dim_2_area, dim_3_type, dim_4_type, in_record[1:]):
                # 走査中の列の地域が前の列と異なる場所で行を分ける
                if len(out_record) > 0 and current_dim[0:2] != dim_val[0:2]:
                    output_dat.append((ymd_val, *current_dim[0:2], out_record))
                    out_record = dict()

                # 地域以外の列は単一列にする
                out_record[" ".join(dim_val[2:4])] = dim_val[4]
                # 走査中の地域列情報を更新
                current_dim = dim_val

            # ループ終了で行分割が行われなかった分の行を出力
            output_dat.append((ymd_val, *current_dim[0:2], out_record))

    measure_set = { key for item in output_dat for key in item[3].keys() }
    measure_set = list(sorted(measure_set))
    output_dat = [dimval[0:3] + tuple(dimval[3].get(mes) for mes in measure_set) for dimval in output_dat]
    with open(out_filepath, mode="wt", encoding="utf8") as f:
        writer = csv.writer(f)
        writer.writerow(["ymd", "area_1", "area_2", *measure_set])
        writer.writerows(output_dat)

convert_src("src/data/tenki_src/data-20190101-20191231.csv", "src/data/tenki/tenki-20190101-20191231.csv")
convert_src("src/data/tenki_src/data-20200101-20201231.csv", "src/data/tenki/tenki-20200101-20201231.csv")
convert_src("src/data/tenki_src/data-20210101-20211231.csv", "src/data/tenki/tenki-20210101-20211231.csv")
convert_src("src/data/tenki_src/data-20220101-20221231.csv", "src/data/tenki/tenki-20220101-20221231.csv")
convert_src("src/data/tenki_src/data-20230101-20231231.csv", "src/data/tenki/tenki-20230101-20231231.csv")

