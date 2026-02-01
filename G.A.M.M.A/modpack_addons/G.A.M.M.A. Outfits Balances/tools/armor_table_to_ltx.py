import csv
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(
        description="Convert a tab-separated TXT table to a STALKER GAMMA LTX file"
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

    OUTFIT_FIELDS = [
        "cost",
        "radiation_protection",
        "chemical_burn_protection",
        "shock_protection",
        "burn_protection",
        "telepatic_protection",
        "strike_protection",
        "explosion_protection",
        "wound_protection",
        "bones_koeff_protection",
        "hit_fraction_actor",
        "artefact_count",
        "additional_inventory_weight",
        "additional_inventory_weight2",
        "inv_weight",
        "repair_type",
    ]

    speed_entries = []

    try:
        with open(INPUT_FILE, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f, delimiter="\t")
            rows = list(reader)
    except FileNotFoundError:
        print(f"Error: input file not found: {INPUT_FILE}", file=sys.stderr)
        sys.exit(1)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
        for row in rows:
            name = row["name"]
            out.write(f"![{name}]\n")

            for field in OUTFIT_FIELDS:
                if field == "additional_inventory_weight2":
                    value = row["additional_inventory_weight"]
                else:
                    value = row.get(field, "")

                out.write(f"{field} = {value}\n")

            out.write("\n")

            speed_entries.append((name, row["Speed"]))

        out.write("![speed]\n")
        for name, speed in speed_entries:
            out.write(f"{name} = {speed}\n")


if __name__ == "__main__":
    main()

