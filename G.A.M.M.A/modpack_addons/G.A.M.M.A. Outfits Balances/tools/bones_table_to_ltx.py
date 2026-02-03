import csv
import argparse
import sys

TRAILING_LINES = [
    "bip01_neck = 1, 0.0",
    "bip01_head = 1, 0.0",
    "eyelid_1 = 1, 0.0",
    "eye_left = 1, 0.0",
    "eye_right = 1, 0.0",
    "jaw_1 = 1, 0.0",
    "ap_scale = 0.9",
]

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

    try:
        with open(args.input, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f, delimiter="\t")
            rows = list(reader)
    except FileNotFoundError:
        print(f"Error: input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    with open(args.output, "w", encoding="utf-8") as out:
        for row in rows:
            section_name = row.get("bones_koeff_protection")
            if not section_name:
                continue

            out.write(f"[{section_name}]\n")

            for column, value in row.items():
                if column == "bones_koeff_protection":
                    continue
                if not column.startswith("bip01_"):
                    continue
                if value == "":
                    continue

                out.write(f"{column} = 1, {value}\n")

            # Bloc fixe ajouté à la fin de chaque section
            for line in TRAILING_LINES:
                out.write(f"{line}\n")

            out.write("\n")


if __name__ == "__main__":
    main()
