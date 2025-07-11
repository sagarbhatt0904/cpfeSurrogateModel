import xml.etree.ElementTree as ET
from xml.dom import minidom



# Function to prettify the XML 
def prettify_xml(element):
    rough_string = ET.tostring(element, 'utf-8')
    parsed = minidom.parseString(rough_string)
    return parsed.toprettyxml(indent="  ", newl="\n", encoding=None).split("\n", 1)[1]  # To remove XML declaration

def generateVoceXML(tau_sat,tau_0,gamma0,n,b):

    materials = ET.Element("materials")

    cpdeformation = ET.SubElement(materials, "cpdeformation", type="SingleCrystalModel")

    kinematics = ET.SubElement(cpdeformation, "kinematics", type="StandardKinematicModel")

    emodel = ET.SubElement(kinematics, "emodel", type="IsotropicLinearElasticModel")
    ET.SubElement(emodel, "m1_type").text = "youngs"
    ET.SubElement(emodel, "m1").text = "101300"
    ET.SubElement(emodel, "m2_type").text = "poissons"
    ET.SubElement(emodel, "m2").text = "0.39"

    imodel = ET.SubElement(kinematics, "imodel", type="AsaroInelasticity")

    rule = ET.SubElement(imodel, "rule", type="PowerLawSlipRule")

    resistance = ET.SubElement(rule, "resistance", type="VoceSlipHardening")
    ET.SubElement(resistance, "tau_sat").text = str(tau_sat)
    ET.SubElement(resistance, "b").text = str(b)
    ET.SubElement(resistance, "tau_0").text = str(tau_0)

    ET.SubElement(rule, "gamma0").text = str(gamma0)
    ET.SubElement(rule, "n").text = str(n)

    lattice = ET.SubElement(cpdeformation, "lattice", type="CubicLattice")
    ET.SubElement(lattice, "a").text = "1.0"
    ET.SubElement(lattice, "slip_systems").text = "1 1 0 ; 1 1 1"


    pretty_xml = prettify_xml(materials)

    return pretty_xml

def gernateHuKocksXML():
    # Add code when ready
    return 0

def writeXML(fileName, materialModel, tau_sat,tau_0,gamma0,n,b):
    correctModelName=False
    # In future This code can be used for Calibration of other models
    if materialModel== 'voce':
        pretty_xml = generateVoceXML(tau_sat,tau_0,gamma0,n,b)
        correctModelName=True
    if correctModelName:
        # Write the XML to a file
        with open(fileName+".xml", "w", encoding="utf-8") as file:
            file.write(pretty_xml)
    else:
        print("Incorrect Model Name!")
        exit(1)