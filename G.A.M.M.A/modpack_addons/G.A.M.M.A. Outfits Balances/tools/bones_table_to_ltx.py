import csv
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(
        description="Convert a tab-separated bone coefficient table to STALKER LTX sections"
    )
    parser.add_argument(
        "-i", "--input",
        required=True,
        help="Input tab-separated TXT file"
    )
    parser.add_argument(
        "-o", "--output",
        required=True,
        help="Output LTX file"
    )

    args = parser.parse_args()

    INPUT_FILE = args.input
    OUTPUT_FILE = args.output

    try:
        with open(INPUT_FILE, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f, delimiter="\t")
            rows = list(reader)
    except FileNotFoundError:
        print(f"Error: input file not found: {INPUT_FILE}", file=sys.stderr)
        sys.exit(1)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
        for row in rows:
            section_name = row.get("bones_koeff_protection")
            if not section_name:
                continue

            out.write(f"![{section_name}]\n")

            for column, value in row.items():
                if column == "bones_koeff_protection":
                    continue
                if not column.startswith("bip01_"):
                    continue
                if value == "":
                    continue

                out.write(f"{column} = {value}\n")

            out.write("\n")


if __name__ == "__main__":
    main()

