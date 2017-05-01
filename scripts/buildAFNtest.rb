require 'openstudio'
#
#
#  +-------------------------------------------------------------+
#  |                          Surface_15                         |
#  |                                                             |
#  |                                                             |
#  |                         north_space                         |
#  |                         north_zone                          |
#  | Surface_14                                       Surface_16 |
#  |                      Floor: Surface_19                      |
#  |                       Roof: Surface_20                      |
#  |                                                             |
#  |                                                             |
#  |          Surface_17                     Surface_18          |
#  +------------------------------+------------------------------+
#  |          Surface_3           |          Surface_11          |
#  |                              |                              |
#  |          west_space          |          east_space          |
#  |          west_zone           |          east_zone           |
#  |                              |                              |
#  | Surface_2          Surface_4 | Surface_10         Surface_9 |
#  |                              |                              |
#  |      Floor: Surface_5        |      Floor: Surface_12       |
#  |       Roof: Surface_6        |       Roof: Surface_13       |
#  |                              |                              |
#  |          Surface_1           |          Surface_8           |
#  +------------------------------+------------------------------+
#
#
#
#
#
#
#
class SurfaceVisitor
  attr_reader :summary

  def initialize(model)
    setup(model)
    run(model)
    shutdown(model)
  end

  def setup(model)
  end

  def run(model)
    allsurfs = model.getSurfaces()
    @surfs = []
    for surf in allsurfs do
      if !@surfs.include?(surf) then
        other = surf.adjacentSurface()
        if !other.empty?() then
          if !@surfs.include?(other.get()) then
            # This is an interior surface
            stype = surf.surfaceType()
            @surfs << surf
            if stype == 'Floor' then
              interiorFloor(model, surf, other.get())
            elsif stype == 'RoofCeiling' then
              interiorRoofCeiling(model, surf, other.get())
            else
              interiorWall(model, surf, other.get())
            end
          end
        else
          # This is an exterior surface
          @surfs << surf
          exteriorSurface(model, surf)
        end
      end
    end
  end

  def interiorFloor(model, surface, adjacentSurface)
  end

  def interiorWall(model, surface, adjacentSurface)
  end

  def interiorRoofCeiling(model, surface, adjacentSurface)
  end

  def exteriorSurface(model, surface)
  end

  def shutdown(model)
    @summary = 'Visited ' + @surfs.size().to_s() + ' surfaces'
  end

end

class SurfaceNetworkBuilder < SurfaceVisitor
  def initialize(model, interiorCrack, exteriorCrack, scaleByArea=false)
    @interiorCrack = interiorCrack
    if interiorCrack == nil then
      @interiorCrack = OpenStudio::Model::AirflowNetworkCrack.new(model, 1.0) # Need to fix multiplier!
    end
    @exteriorCrack = exteriorCrack
    if interiorCrack == nil then
      @exteriorCrack = OpenStudio::Model::AirflowNetworkCrack.new(model, 1.0) # Need to fix multiplier!
    end
    @scaleByArea = scaleByArea
    super(model)
  end

  def interiorFloor(model, surface, adjacentSurface)
    if !surface.outsideBoundaryCondition().start_with?('Ground') then
      # Create a surface linkage
      link = OpenStudio::Model::AirflowNetworkSurface.new(model,surface,@interiorCrack)
    end
  end

  def interiorRoofCeiling(model, surface, adjacentSurface)
    # Create a surface linkage
    link = OpenStudio::Model::AirflowNetworkSurface.new(model,surface,@interiorCrack)
  end

  def interiorWall(model, surface, adjacentSurface)
    # Create a surface linkage
    link = OpenStudio::Model::AirflowNetworkSurface.new(model,surface,@interiorCrack)
  end

  def exteriorSurface(model, surface)
    # Create an external node
    # Create a surface linkage
    link = OpenStudio::Model::AirflowNetworkSurface.new(model,surface,@exteriorCrack)
  end
end

def addSurfaceCracks(model, intcrack, extcrack, scaledByArea=false)
  allsurfs = model.getSurfaces()
  surfs = []
  for surf in allsurfs do
    if !surfs.include?(surf) then
      other = surf.adjacentSurface()
      if !other.empty?() then
        if !surfs.include?(other.get()) then
          # This is an interior surface
          surfs << surf
        end
      else
        # This is an exterior surface
        surfs << surf
      end
    end
  end
  puts surfs.size()
  #puts extsurfs.size()
end

model = OpenStudio::Model::Model.new()

# Material,A1 - 1 IN STUCCO,Smooth,2.5389841E-02,0.6918309,1858.142,836.8000,0.9000000,0.9200000,0.9200000
stucco = OpenStudio::Model::StandardOpaqueMaterial.new(model, "Smooth", 2.5389841E-02, 0.6918309, 1858.142, 836.8)
stucco.setThermalAbsorptance(0.9)
stucco.setSolarAbsorptance(0.92)
stucco.setVisibleAbsorptance(0.92)

# Material,C4 - 4 IN COMMON BRICK,Rough,0.1014984,0.7264224,1922.216,836.8000,0.9000000,0.7600000,0.7600000
brick = OpenStudio::Model::StandardOpaqueMaterial.new(model, "Rough", 0.1014984, 0.7264224, 1922.216, 836.8)
brick.setThermalAbsorptance(0.9)
brick.setSolarAbsorptance(0.76)
brick.setVisibleAbsorptance(0.76)

# Material,E1 - 3 / 4 IN PLASTER OR GYP BOARD,Smooth,1.905E-02,0.7264224,1601.846,836.8000,0.9000000,0.9200000,0.9200000
wallboard = OpenStudio::Model::StandardOpaqueMaterial.new(model, "Smooth", 1.905E-02, 0.7264224, 1601.846, 836.8)
wallboard.setThermalAbsorptance(0.92)
wallboard.setSolarAbsorptance(0.92)
wallboard.setVisibleAbsorptance(0.9)

# Material,C6 - 8 IN CLAY TILE,Smooth,0.2033016,0.5707605,1121.292,836.8000,0.9000000,0.8200000,0.8200000
tile = OpenStudio::Model::StandardOpaqueMaterial.new(model, "Smooth", 0.2033016, 0.5707605, 1121.292, 836.8)
tile.setThermalAbsorptance(0.82)
tile.setSolarAbsorptance(0.82)
tile.setVisibleAbsorptance(0.9)

# Material,C10 - 8 IN HW CONCRETE,MediumRough,0.2033016,1.729577,2242.585,836.8000,0.9000000,0.6500000,0.6500000
concrete8 = OpenStudio::Model::StandardOpaqueMaterial.new(model, "MediumRough", 0.2033016, 1.729577, 2242.585, 836.8)
concrete8.setThermalAbsorptance(0.65)
concrete8.setSolarAbsorptance(0.65)
concrete8.setVisibleAbsorptance(0.9)

# Material,E2 - 1 / 2 IN SLAG OR STONE,Rough,1.2710161E-02,1.435549,881.0155,1673.600,0.9000000,0.5500000,0.5500000
stone = OpenStudio::Model::StandardOpaqueMaterial.new(model, "Rough", 1.2710161E-02, 1.435549, 881.0155, 1673.6)
stone.setThermalAbsorptance(0.55)
stone.setSolarAbsorptance(0.55)
stone.setVisibleAbsorptance(0.9)

# Material,E3 - 3 / 8 IN FELT AND MEMBRANE,Rough,9.5402403E-03,0.1902535,1121.292,1673.600,0.9000000,0.7500000,0.7500000
membrane = OpenStudio::Model::StandardOpaqueMaterial.new(model, "Rough", 9.5402403E-03, 0.1902535, 1121.292, 1673.6)
membrane.setThermalAbsorptance(0.75)
membrane.setSolarAbsorptance(0.75)
membrane.setVisibleAbsorptance(0.9)

# Material,B5 - 1 IN DENSE INSULATION,VeryRough,2.5389841E-02,4.3239430E-02,91.30524,836.8000,0.9000000,0.5000000,0.5000000
insulation = OpenStudio::Model::StandardOpaqueMaterial.new(model, "VeryRough", 2.5389841E-02, 4.3239430E-02, 91.30524, 836.8)
insulation.setThermalAbsorptance(0.5)
insulation.setSolarAbsorptance(0.5)
insulation.setVisibleAbsorptance(0.9)

# Material,C12 - 2 IN HW CONCRETE,MediumRough,5.0901599E-02,1.729577,2242.585,836.8000,0.9000000,0.6500000,0.6500000
concrete2 = OpenStudio::Model::StandardOpaqueMaterial.new(model, "MediumRough", 5.0901599E-02, 1.729577, 2242.585, 836.8)
concrete2.setThermalAbsorptance(0.65)
concrete2.setSolarAbsorptance(0.65)
concrete2.setVisibleAbsorptance(0.9)

# Material,1.375in-Solid-Core,Smooth,3.4925E-02,0.1525000,614.5000,1630.0000,0.9000000,0.9200000,0.9200000
solidcore = OpenStudio::Model::StandardOpaqueMaterial.new(model, "Smooth", 3.4925E-02, 0.1525, 614.50, 1630.0)
solidcore.setThermalAbsorptance(0.92)
solidcore.setSolarAbsorptance(0.92)
solidcore.setVisibleAbsorptance(0.9)

# WindowMaterial:Glazing,WIN-LAY-GLASS-LIGHT,SpectralAverage,0.0025,0.850,0.075,0.075,0.901,0.081,0.081,0.0,0.84,0.84,0.9
glazing = OpenStudio::Model::StandardGlazing.new(model, "SpectralAverage", 0.0025)
glazing.setSolarTransmittanceatNormalIncidence(0.850)
glazing.setFrontSideSolarReflectanceatNormalIncidence(0.075)
glazing.setBackSideSolarReflectanceatNormalIncidence(0.075)
glazing.setVisibleTransmittanceatNormalIncidence(0.901)
glazing.setFrontSideVisibleReflectanceatNormalIncidence(0.081)
glazing.setBackSideVisibleReflectanceatNormalIncidence(0.08)
glazing.setInfraredTransmittanceatNormalIncidence(0.0)
glazing.setFrontSideInfraredHemisphericalEmissivity(0.84)
glazing.setBackSideInfraredHemisphericalEmissivity(0.84)
glazing.setConductivity(0.9)

materials = OpenStudio::Model::OpaqueMaterialVector.new()

# Construction,DOOR-CON,1.375in-Solid-Core
materials << solidcore
door = OpenStudio::Model::Construction.new(materials)

# Construction,EXTWALL80,A1 - 1 IN STUCCO,C4 - 4 IN COMMON BRICK,E1 - 3 / 4 IN PLASTER OR GYP BOARD
materials.clear()
materials << stucco
materials << brick
materials << wallboard
extwall = OpenStudio::Model::Construction.new(materials)

# Construction,PARTITION06,E1 - 3 / 4 IN PLASTER OR GYP BOARD,C6 - 8 IN CLAY TILE,E1 - 3 / 4 IN PLASTER OR GYP BOARD
materials.clear()
materials << wallboard
materials << tile
materials << wallboard
partition = OpenStudio::Model::Construction.new(materials)

# Construction,FLOOR SLAB 8 IN,C10 - 8 IN HW CONCRETE
materials.clear()
materials << concrete8
floorslab = OpenStudio::Model::Construction.new(materials)

# Construction,ROOF34,E2 - 1 / 2 IN SLAG OR STONE,E3 - 3 / 8 IN FELT AND MEMBRANE,B5 - 1 IN DENSE INSULATION,C12 - 2 IN HW CONCRETE
materials.clear()
materials << stone
materials << membrane
materials << insulation
materials << concrete2
roof = OpenStudio::Model::Construction.new(materials)

# Construction,WIN-CON-LIGHT,WIN-LAY-GLASS-LIGHT
#materials = OpenStudio::Model::StandardGlazingVector.new()
materials = OpenStudio::Model::FenestrationMaterialVector.new()
materials.clear()
materials << glazing
lightwindow = OpenStudio::Model::Construction.new(materials)

points = OpenStudio::Point3dVector.new

# BuildingSurface:Detailed,Surface_1,WALL,EXTWALL80,WEST_ZONE,Outdoors,,SunExposed,WindExposed,0.5000000,4,0,0,3.048000,0,0,0,6.096000,0,0,6.096000,0,3.048000
points << OpenStudio::Point3d.new(0, 0, 3.048000)
points << OpenStudio::Point3d.new(0, 0, 0)
points << OpenStudio::Point3d.new(6.096000, 0, 0)
points << OpenStudio::Point3d.new(6.096000, 0, 3.048000)
surface_1 = OpenStudio::Model::Surface.new(points, model)
surface_1.setSurfaceType("WALL")
surface_1.setSunExposure("SunExposed")
surface_1.setWindExposure("WindExposed")
surface_1.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_2,WALL,EXTWALL80,WEST_ZONE,Outdoors,,SunExposed,WindExposed,0.5000000,4,0,6.096000,3.048000,0,6.096000,0,0,0,0,0,0,3.048000
points.clear
points << OpenStudio::Point3d.new(0, 6.096000, 3.048000)
points << OpenStudio::Point3d.new(0, 6.096000, 0)
points << OpenStudio::Point3d.new(0, 0, 0)
points << OpenStudio::Point3d.new(0, 0, 3.048000)
surface_2 = OpenStudio::Model::Surface.new(points, model)
surface_2.setSurfaceType("WALL")
surface_2.setSunExposure("SunExposed")
surface_2.setWindExposure("WindExposed")
surface_2.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_3,WALL,PARTITION06,WEST_ZONE,Surface,Surface_17,NoSun,NoWind,0.5000000,4,6.096000,6.096000,3.048000,6.096000,6.096000,0,0,6.096000,0,0,6.096000,3.048000
points.clear
points << OpenStudio::Point3d.new(6.096000, 6.096000, 3.048000)
points << OpenStudio::Point3d.new(6.096000, 6.096000, 0)
points << OpenStudio::Point3d.new(0, 6.096000, 0)
points << OpenStudio::Point3d.new(0, 6.096000, 3.048000)
surface_3 = OpenStudio::Model::Surface.new(points, model)
surface_3.setSurfaceType("WALL")
surface_3.setSunExposure("NoSun")
surface_3.setWindExposure("NoWind")
surface_3.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_4,WALL,PARTITION06,WEST_ZONE,Surface,Surface_10,NoSun,NoWind,0.5000000,4,6.096000,0,3.048000,6.096000,0,0,6.096000,6.096000,0,6.096000,6.096000,3.048000
points.clear
points << OpenStudio::Point3d.new(6.096000, 0, 3.048000)
points << OpenStudio::Point3d.new(6.096000, 0, 0)
points << OpenStudio::Point3d.new(6.096000, 6.096000, 0)
points << OpenStudio::Point3d.new(6.096000, 6.096000, 3.048000)
surface_4 = OpenStudio::Model::Surface.new(points, model)
surface_4.setSurfaceType("WALL")
surface_4.setSunExposure("NoSun")
surface_4.setWindExposure("NoWind")
surface_4.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_5,FLOOR,FLOOR SLAB 8 IN,WEST_ZONE,Surface,Surface_5,NoSun,NoWind,1.000000,4,0,0,0,0,6.096000,0,6.096000,6.096000,0,6.096000,0,0
points.clear
points << OpenStudio::Point3d.new(0, 0, 0)
points << OpenStudio::Point3d.new(0, 6.096000, 0)
points << OpenStudio::Point3d.new(6.096000, 6.096000, 0)
points << OpenStudio::Point3d.new(6.096000, 0, 0)
surface_5 = OpenStudio::Model::Surface.new(points, model)
surface_5.setSurfaceType("FLOOR")
surface_5.setSunExposure("NoSun")
surface_5.setWindExposure("NoWind")
surface_5.setViewFactortoGround(1.000000)
# BuildingSurface:Detailed,Surface_6,ROOF,ROOF34,WEST_ZONE,Outdoors,,SunExposed,WindExposed,0,4,0,6.096000,3.048000,0,0,3.048000,6.096000,0,3.048000,6.096000,6.096000,3.048000
points.clear
points << OpenStudio::Point3d.new(0, 6.096000, 3.048000)
points << OpenStudio::Point3d.new(0, 0, 3.048000)
points << OpenStudio::Point3d.new(6.096000, 0, 3.048000)
points << OpenStudio::Point3d.new(6.096000, 6.096000, 3.048000)
surface_6 = OpenStudio::Model::Surface.new(points, model)
surface_6.setSurfaceType("ROOF")
surface_6.setSunExposure("SunExposed")
surface_6.setWindExposure("WindExposed")
surface_6.setViewFactortoGround(0)
# BuildingSurface:Detailed,Surface_8,WALL,EXTWALL80,EAST_ZONE,Outdoors,,SunExposed,WindExposed,0.5000000,4,6.096000,0,3.048000,6.096000,0,0,12.19200,0,0,12.19200,0,3.048000
points.clear
points << OpenStudio::Point3d.new(6.096000, 0, 3.048000)
points << OpenStudio::Point3d.new(6.096000, 0, 0)
points << OpenStudio::Point3d.new(12.19200, 0, 0)
points << OpenStudio::Point3d.new(12.19200, 0, 3.048000)
surface_8 = OpenStudio::Model::Surface.new(points, model)
surface_8.setSurfaceType("WALL")
surface_8.setSunExposure("SunExposed")
surface_8.setWindExposure("WindExposed")
surface_8.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_9,WALL,EXTWALL80,EAST_ZONE,Outdoors,,SunExposed,WindExposed,0.5000000,4,12.19200,0,3.048000,12.19200,0,0,12.19200,6.096000,0,12.19200,6.096000,3.048000
points.clear
points << OpenStudio::Point3d.new(12.19200, 0, 3.048000)
points << OpenStudio::Point3d.new(12.19200, 0, 0)
points << OpenStudio::Point3d.new(12.19200, 6.096000, 0)
points << OpenStudio::Point3d.new(12.19200, 6.096000, 3.048000)
surface_9 = OpenStudio::Model::Surface.new(points, model)
surface_9.setSurfaceType("WALL")
surface_9.setSunExposure("SunExposed")
surface_9.setWindExposure("WindExposed")
surface_9.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_10,WALL,PARTITION06,EAST_ZONE,Surface,Surface_4,NoSun,NoWind,0.5000000,4,6.096000,6.096000,3.048000,6.096000,6.096000,0,6.096000,0,0,6.096001,0,3.048000
points.clear
points << OpenStudio::Point3d.new(6.096000, 6.096000, 3.048000)
points << OpenStudio::Point3d.new(6.096000, 6.096000, 0)
points << OpenStudio::Point3d.new(6.096000, 0, 0)
points << OpenStudio::Point3d.new(6.096001, 0, 3.048000)
surface_10 = OpenStudio::Model::Surface.new(points, model)
surface_10.setSurfaceType("WALL")
surface_10.setSunExposure("NoSun")
surface_10.setWindExposure("NoWind")
surface_10.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_11,WALL,PARTITION06,EAST_ZONE,Surface,Surface_18,NoSun,NoWind,0.5000000,4,12.19200,6.096000,3.048000,12.19200,6.096000,0,6.096000,6.096000,0,6.096000,6.096000,3.048000
points.clear
points << OpenStudio::Point3d.new(12.19200, 6.096000, 3.048000)
points << OpenStudio::Point3d.new(12.19200, 6.096000, 0)
points << OpenStudio::Point3d.new(6.096000, 6.096000, 0)
points << OpenStudio::Point3d.new(6.096000, 6.096000, 3.048000)
surface_11 = OpenStudio::Model::Surface.new(points, model)
surface_11.setSurfaceType("WALL")
surface_11.setSunExposure("NoSun")
surface_11.setWindExposure("NoWind")
surface_11.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_12,FLOOR,FLOOR SLAB 8 IN,EAST_ZONE,Surface,Surface_12,NoSun,NoWind,1.000000,4,6.096000,0,0,6.096000,6.096000,0,12.19200,6.096000,0,12.19200,0,0
points.clear
points << OpenStudio::Point3d.new(6.096000, 0, 0)
points << OpenStudio::Point3d.new(6.096000, 6.096000, 0)
points << OpenStudio::Point3d.new(12.19200, 6.096000, 0)
points << OpenStudio::Point3d.new(12.19200, 0, 0)
surface_12 = OpenStudio::Model::Surface.new(points, model)
surface_12.setSurfaceType("FLOOR")
surface_12.setSunExposure("NoSun")
surface_12.setWindExposure("NoWind")
surface_12.setViewFactortoGround(1.000000)
# BuildingSurface:Detailed,Surface_13,ROOF,ROOF34,EAST_ZONE,Outdoors,,SunExposed,WindExposed,0,4,6.096000,6.096000,3.048000,6.096000,0,3.048000,12.19200,0,3.048000,12.19200,6.096000,3.048000
points.clear
points << OpenStudio::Point3d.new(6.096000, 6.096000, 3.048000)
points << OpenStudio::Point3d.new(6.096000, 0, 3.048000)
points << OpenStudio::Point3d.new(12.19200, 0, 3.048000)
points << OpenStudio::Point3d.new(12.19200, 6.096000, 3.048000)
surface_13 = OpenStudio::Model::Surface.new(points, model)
surface_13.setSurfaceType("ROOF")
surface_13.setSunExposure("SunExposed")
surface_13.setWindExposure("WindExposed")
surface_13.setViewFactortoGround(0)
# BuildingSurface:Detailed,Surface_14,WALL,EXTWALL80,NORTH_ZONE,Outdoors,,SunExposed,WindExposed,0.5000000,4,0,12.19200,3.048000,0,12.19200,0,0,6.096000,0,0,6.096000,3.048000
points.clear
points << OpenStudio::Point3d.new(0, 12.19200, 3.048000)
points << OpenStudio::Point3d.new(0, 12.19200, 0)
points << OpenStudio::Point3d.new(0, 6.096000, 0)
points << OpenStudio::Point3d.new(0, 6.096000, 3.048000)
surface_14 = OpenStudio::Model::Surface.new(points, model)
surface_14.setSurfaceType("WALL")
surface_14.setSunExposure("SunExposed")
surface_14.setWindExposure("WindExposed")
surface_14.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_15,WALL,EXTWALL80,NORTH_ZONE,Outdoors,,SunExposed,WindExposed,0.5000000,4,12.19200,12.19200,3.048000,12.19200,12.19200,0,0,12.19200,0,0,12.19200,3.048000
points.clear
points << OpenStudio::Point3d.new(12.19200, 12.19200, 3.048000)
points << OpenStudio::Point3d.new(12.19200, 12.19200, 0)
points << OpenStudio::Point3d.new(0, 12.19200, 0)
points << OpenStudio::Point3d.new(0, 12.19200, 3.048000)
surface_15 = OpenStudio::Model::Surface.new(points, model)
surface_15.setSurfaceType("WALL")
surface_15.setSunExposure("SunExposed")
surface_15.setWindExposure("WindExposed")
surface_15.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_16,WALL,EXTWALL80,NORTH_ZONE,Outdoors,,SunExposed,WindExposed,0.5000000,4,12.19200,6.096000,3.048000,12.19200,6.096000,0,12.19200,12.19200,0,12.19200,12.19200,3.048000
points.clear
points << OpenStudio::Point3d.new(12.19200, 6.096000, 3.048000)
points << OpenStudio::Point3d.new(12.19200, 6.096000, 0)
points << OpenStudio::Point3d.new(12.19200, 12.19200, 0)
points << OpenStudio::Point3d.new(12.19200, 12.19200, 3.048000)
surface_16 = OpenStudio::Model::Surface.new(points, model)
surface_16.setSurfaceType("WALL")
surface_16.setSunExposure("SunExposed")
surface_16.setWindExposure("WindExposed")
surface_16.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_17,WALL,PARTITION06,NORTH_ZONE,Surface,Surface_3,NoSun,NoWind,0.5000000,4,0.000,6.096,3.048,0.000,6.096,0.000,6.096,6.096,0.000,6.096,6.096,3.048
points.clear
points << OpenStudio::Point3d.new(0.000, 6.096, 3.048)
points << OpenStudio::Point3d.new(0.000, 6.096, 0.000)
points << OpenStudio::Point3d.new(6.096, 6.096, 0.000)
points << OpenStudio::Point3d.new(6.096, 6.096, 3.048)
surface_17 = OpenStudio::Model::Surface.new(points, model)
surface_17.setSurfaceType("WALL")
surface_17.setSunExposure("NoSun")
surface_17.setWindExposure("NoWind")
surface_17.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_18,WALL,PARTITION06,NORTH_ZONE,Surface,Surface_11,NoSun,NoWind,0.5000000,4,6.096000,6.096000,3.048000,6.096000,6.096000,0,12.19200,6.096000,0,12.19200,6.096000,3.048000
points.clear
points << OpenStudio::Point3d.new(6.096000, 6.096000, 3.048000)
points << OpenStudio::Point3d.new(6.096000, 6.096000, 0)
points << OpenStudio::Point3d.new(12.19200, 6.096000, 0)
points << OpenStudio::Point3d.new(12.19200, 6.096000, 3.048000)
surface_18 = OpenStudio::Model::Surface.new(points, model)
surface_18.setSurfaceType("WALL")
surface_18.setSunExposure("NoSun")
surface_18.setWindExposure("NoWind")
surface_18.setViewFactortoGround(0.5000000)
# BuildingSurface:Detailed,Surface_19,FLOOR,FLOOR SLAB 8 IN,NORTH_ZONE,Surface,Surface_19,NoSun,NoWind,1.000000,4,0,6.096000,0,0,12.19200,0,12.19200,12.19200,0,12.19200,6.096000,0
points.clear
points << OpenStudio::Point3d.new(0, 6.096000, 0)
points << OpenStudio::Point3d.new(0, 12.19200, 0)
points << OpenStudio::Point3d.new(12.19200, 12.19200, 0)
points << OpenStudio::Point3d.new(12.19200, 6.096000, 0)
surface_19 = OpenStudio::Model::Surface.new(points, model)
surface_19.setSurfaceType("FLOOR")
surface_19.setSunExposure("NoSun")
surface_19.setWindExposure("NoWind")
surface_19.setViewFactortoGround(1.000000)
# BuildingSurface:Detailed,Surface_20,ROOF,ROOF34,NORTH_ZONE,Outdoors,,SunExposed,WindExposed,0,4,0,12.19200,3.048000,0,6.096000,3.048000,12.19200,6.096000,3.048000,12.19200,12.19200,3.048000
points.clear
points << OpenStudio::Point3d.new(0, 12.19200, 3.048000)
points << OpenStudio::Point3d.new(0, 6.096000, 3.048000)
points << OpenStudio::Point3d.new(12.19200, 6.096000, 3.048000)
points << OpenStudio::Point3d.new(12.19200, 12.19200, 3.048000)
surface_20 = OpenStudio::Model::Surface.new(points, model)
surface_20.setSurfaceType("ROOF")
surface_20.setSunExposure("SunExposed")
surface_20.setWindExposure("WindExposed")
surface_20.setViewFactortoGround(0)

# Set the constructions
surface_1.setConstruction(extwall)
surface_2.setConstruction(extwall)
surface_3.setConstruction(partition)
surface_4.setConstruction(partition)
surface_5.setConstruction(floorslab)
surface_6.setConstruction(roof)
#surface_7.setConstruction(extwall)
surface_8.setConstruction(extwall)
surface_9.setConstruction(extwall)
surface_10.setConstruction(partition)
surface_11.setConstruction(partition)
surface_12.setConstruction(floorslab)
surface_13.setConstruction(roof)
surface_14.setConstruction(extwall)
surface_15.setConstruction(extwall)
surface_16.setConstruction(extwall)
surface_17.setConstruction(partition)
surface_18.setConstruction(partition)
surface_19.setConstruction(floorslab)
surface_20.setConstruction(roof)

# Connect the surfaces together
surface_3.setAdjacentSurface(surface_17)
surface_4.setAdjacentSurface(surface_10)
surface_11.setAdjacentSurface(surface_18)

# Make spaces and thermal zones
west_space = OpenStudio::Model::Space.new(model)
west_zone = OpenStudio::Model::ThermalZone.new(model)
east_space = OpenStudio::Model::Space.new(model)
east_zone = OpenStudio::Model::ThermalZone.new(model)
north_space = OpenStudio::Model::Space.new(model)
north_zone = OpenStudio::Model::ThermalZone.new(model)

# Connect spaces and surfaces
surface_1.setSpace(west_space)
surface_2.setSpace(west_space)
surface_3.setSpace(west_space)
surface_4.setSpace(west_space)
surface_5.setSpace(west_space)
surface_6.setSpace(west_space)

surface_8.setSpace(east_space)
surface_9.setSpace(east_space)
surface_10.setSpace(east_space)
surface_11.setSpace(east_space)
surface_12.setSpace(east_space)
surface_13.setSpace(east_space)

surface_14.setSpace(north_space)
surface_15.setSpace(north_space)
surface_16.setSpace(north_space)
surface_17.setSpace(north_space)
surface_18.setSpace(north_space)
surface_19.setSpace(north_space)
surface_20.setSpace(north_space)

# Connect spaces and zones
west_space.setThermalZone(west_zone)
east_space.setThermalZone(east_zone)
north_space.setThermalZone(north_zone)

puts surface_3.to_s
puts surface_17.to_s
puts surface_3.isNumberofVerticesAutocalculated

addSurfaceCracks(model, nil, nil)

visitor = SurfaceNetworkBuilder.new(model, nil, nil)
puts visitor.summary

puts
zones = model.getAirflowNetworkZones()
puts 'Created ' + zones.size().to_s() + ' AFN zones'
extnodes = model.getAirflowNetworkExternalNodes()
puts 'Created ' + extnodes.size().to_s() + ' AFN external nodes'
surfs = model.getAirflowNetworkSurfaces()
puts 'Created ' + surfs.size().to_s() + ' AFN surfaces'
cracks = model.getAirflowNetworkCracks()
puts 'Created ' + cracks.size().to_s() + ' AFN cracks'

junk = <<-MLS
GlobalGeometryRules,UpperLeftCorner,CounterClockWise,World

FenestrationSurface:Detailed,WINDOW11,WINDOW,WIN-CON-LIGHT,Surface_1,0.5000000,1.0,3,1.00000,0,2.500000,1.00000,0,1.0000000,5.000000,0,1.0000000
FenestrationSurface:Detailed,WINDOW12,WINDOW,WIN-CON-LIGHT,Surface_1,0.5000000,1.0,3,5.00000,0,1.0000000,5.000000,0,2.5000000,1.000000,0,2.500000
FenestrationSurface:Detailed,DoorInSurface_3,DOOR,DOOR-CON,Surface_3,DoorInSurface_17,0.5000000,1.0,4,3.500,6.096000,2.0,3.500,6.096000,0.0,2.500,6.096000,0.0,2.500,6.096000,2.0
FenestrationSurface:Detailed,WINDOW2,WINDOW,WIN-CON-LIGHT,Surface_15,0.5000000,1.0,4,6.000000,12.19200,2.333000,6.000000,12.19200,1.000000,3.000000,12.19200,1.000000,3.000000,12.19200,2.333000
FenestrationSurface:Detailed,DoorInSurface_17,DOOR,DOOR-CON,Surface_17,DoorInSurface_3,0.5000000,1.0,4,2.500,6.096000,2.0,2.500,6.096000,0.0,3.500,6.096000,0.0,3.500,6.096000,2.0

AirflowNetwork:SimulationControl,NaturalVentilation,MultizoneWithoutDistribution,INPUT,ExternalNode,LOWRISE,500,ZeroNodePressures,1.0E-05,1.0E-06,-0.5,0.0,1.0

AirflowNetwork:MultiZone:Zone,WEST_ZONE,NoVent,Temperature,WindowVentSched,0.3,5.0,10.0,0.0,300000.0
AirflowNetwork:MultiZone:Zone,EAST_ZONE,NoVent,1.0,0.0,100.0,0.0,300000.0
AirflowNetwork:MultiZone:Zone,NORTH_ZONE,NoVent,Temperature,WindowVentSched,1.0,0.0,100.0,0.0,300000.0
AirflowNetwork:MultiZone:Surface,Surface_1,CR-1,SFacade,1.0
AirflowNetwork:MultiZone:Surface,Surface_4,CR-1,1.0
AirflowNetwork:MultiZone:Surface,Surface_11,CR-1,1.0
AirflowNetwork:MultiZone:Surface,Surface_15,CR-1,NFacade,1.0
AirflowNetwork:MultiZone:ExternalNode,NFacade,1.524,NFacade_WPCValue
AirflowNetwork:MultiZone:ExternalNode,SFacade,1.524,SFacade_WPCValue,No,Absolute
AirflowNetwork:MultiZone:ReferenceCrackConditions,ReferenceCrackConditions,20.0,101320,0.005
AirflowNetwork:MultiZone:Surface:Crack,CR-1,0.01,0.667,ReferenceCrackConditions
AirflowNetwork:MultiZone:WindPressureCoefficientArray,Every 30 Degrees,0,30,60,90,120,150,180,210,240,270,300,330
AirflowNetwork:MultiZone:WindPressureCoefficientValues,NFacade_WPCValue,Every 30 Degrees,0.60,0.48,0.04,-0.56,-0.56,-0.42,-0.37,-0.42,-0.56,-0.56,0.04,0.48
AirflowNetwork:MultiZone:WindPressureCoefficientValues,SFacade_WPCValue,Every 30 Degrees,-0.37,-0.42,-0.56,-0.56,0.04,0.48,0.60,0.48,0.04,-0.56,-0.56,-0.42

SurfaceConvectionAlgorithm:Inside,TARP
SurfaceConvectionAlgorithm:Outside,DOE-2
HeatBalanceAlgorithm,ConductionTransferFunction
ZoneAirHeatBalanceAlgorithm,AnalyticalSolution


TEST_F(EnergyPlusFixture, TestExternalNodes) {
		std::string const idf_objects = delimited_string({
			"Version,8.6;",
			"Material,",
			"  A1 - 1 IN STUCCO,        !- Name",
			"  Smooth,                  !- Roughness",
			"  2.5389841E-02,           !- Thickness {m}",
			"  0.6918309,               !- Conductivity {W/m-K}",
			"  1858.142,                !- Density {kg/m3}",
			"  836.8000,                !- Specific Heat {J/kg-K}",
			"  0.9000000,               !- Thermal Absorptance",
			"  0.9200000,               !- Solar Absorptance",
			"  0.9200000;               !- Visible Absorptance",
			"Material,",
			"  C4 - 4 IN COMMON BRICK,  !- Name",
			"  Rough,                   !- Roughness",
			"  0.1014984,               !- Thickness {m}",
			"  0.7264224,               !- Conductivity {W/m-K}",
			"  1922.216,                !- Density {kg/m3}",
			"  836.8000,                !- Specific Heat {J/kg-K}",
			"  0.9000000,               !- Thermal Absorptance",
			"  0.7600000,               !- Solar Absorptance",
			"  0.7600000;               !- Visible Absorptance",
			"Material,",
			"  E1 - 3 / 4 IN PLASTER OR GYP BOARD,  !- Name",
			"  Smooth,                  !- Roughness",
			"  1.905E-02,               !- Thickness {m}",
			"  0.7264224,               !- Conductivity {W/m-K}",
			"  1601.846,                !- Density {kg/m3}",
			"  836.8000,                !- Specific Heat {J/kg-K}",
			"  0.9000000,               !- Thermal Absorptance",
			"  0.9200000,               !- Solar Absorptance",
			"  0.9200000;               !- Visible Absorptance",
			"Material,",
			"  C6 - 8 IN CLAY TILE,     !- Name",
			"  Smooth,                  !- Roughness",
			"  0.2033016,               !- Thickness {m}",
			"  0.5707605,               !- Conductivity {W/m-K}",
			"  1121.292,                !- Density {kg/m3}",
			"  836.8000,                !- Specific Heat {J/kg-K}",
			"  0.9000000,               !- Thermal Absorptance",
			"  0.8200000,               !- Solar Absorptance",
			"  0.8200000;               !- Visible Absorptance",
			"Material,",
			"  C10 - 8 IN HW CONCRETE,  !- Name",
			"  MediumRough,             !- Roughness",
			"  0.2033016,               !- Thickness {m}",
			"  1.729577,                !- Conductivity {W/m-K}",
			"  2242.585,                !- Density {kg/m3}",
			"  836.8000,                !- Specific Heat {J/kg-K}",
			"  0.9000000,               !- Thermal Absorptance",
			"  0.6500000,               !- Solar Absorptance",
			"  0.6500000;               !- Visible Absorptance",
			"Material,",
			"  E2 - 1 / 2 IN SLAG OR STONE,  !- Name",
			"  Rough,                   !- Roughness",
			"  1.2710161E-02,           !- Thickness {m}",
			"  1.435549,                !- Conductivity {W/m-K}",
			"  881.0155,                !- Density {kg/m3}",
			"  1673.600,                !- Specific Heat {J/kg-K}",
			"  0.9000000,               !- Thermal Absorptance",
			"  0.5500000,               !- Solar Absorptance",
			"  0.5500000;               !- Visible Absorptance",
			"Material,",
			"  E3 - 3 / 8 IN FELT AND MEMBRANE,  !- Name",
			"  Rough,                   !- Roughness",
			"  9.5402403E-03,           !- Thickness {m}",
			"  0.1902535,               !- Conductivity {W/m-K}",
			"  1121.292,                !- Density {kg/m3}",
			"  1673.600,                !- Specific Heat {J/kg-K}",
			"  0.9000000,               !- Thermal Absorptance",
			"  0.7500000,               !- Solar Absorptance",
			"  0.7500000;               !- Visible Absorptance",
			"Material,",
			"  B5 - 1 IN DENSE INSULATION,  !- Name",
			"  VeryRough,               !- Roughness",
			"  2.5389841E-02,           !- Thickness {m}",
			"  4.3239430E-02,           !- Conductivity {W/m-K}",
			"  91.30524,                !- Density {kg/m3}",
			"  836.8000,                !- Specific Heat {J/kg-K}",
			"  0.9000000,               !- Thermal Absorptance",
			"  0.5000000,               !- Solar Absorptance",
			"  0.5000000;               !- Visible Absorptance",
			"Material,",
			"  C12 - 2 IN HW CONCRETE,  !- Name",
			"  MediumRough,             !- Roughness",
			"  5.0901599E-02,           !- Thickness {m}",
			"  1.729577,                !- Conductivity {W/m-K}",
			"  2242.585,                !- Density {kg/m3}",
			"  836.8000,                !- Specific Heat {J/kg-K}",
			"  0.9000000,               !- Thermal Absorptance",
			"  0.6500000,               !- Solar Absorptance",
			"  0.6500000;               !- Visible Absorptance",
			"Material,",
			"  1.375in-Solid-Core,      !- Name",
			"  Smooth,                  !- Roughness",
			"  3.4925E-02,              !- Thickness {m}",
			"  0.1525000,               !- Conductivity {W/m-K}",
			"  614.5000,                !- Density {kg/m3}",
			"  1630.0000,               !- Specific Heat {J/kg-K}",
			"  0.9000000,               !- Thermal Absorptance",
			"  0.9200000,               !- Solar Absorptance",
			"  0.9200000;               !- Visible Absorptance",
			"WindowMaterial:Glazing,",
			"  WIN-LAY-GLASS-LIGHT,     !- Name",
			"  SpectralAverage,         !- Optical Data Type",
			"  ,                        !- Window Glass Spectral Data Set Name",
			"  0.0025,                  !- Thickness {m}",
			"  0.850,                   !- Solar Transmittance at Normal Incidence",
			"  0.075,                   !- Front Side Solar Reflectance at Normal Incidence",
			"  0.075,                   !- Back Side Solar Reflectance at Normal Incidence",
			"  0.901,                   !- Visible Transmittance at Normal Incidence",
			"  0.081,                   !- Front Side Visible Reflectance at Normal Incidence",
			"  0.081,                   !- Back Side Visible Reflectance at Normal Incidence",
			"  0.0,                     !- Infrared Transmittance at Normal Incidence",
			"  0.84,                    !- Front Side Infrared Hemispherical Emissivity",
			"  0.84,                    !- Back Side Infrared Hemispherical Emissivity",
			"  0.9;                     !- Conductivity {W/m-K}",
			"Construction,",
			"  DOOR-CON,                !- Name",
			"  1.375in-Solid-Core;      !- Outside Layer",
			"Construction,",
			"  EXTWALL80,               !- Name",
			"  A1 - 1 IN STUCCO,        !- Outside Layer",
			"  C4 - 4 IN COMMON BRICK,  !- Layer 2",
			"  E1 - 3 / 4 IN PLASTER OR GYP BOARD;  !- Layer 3",
			"Construction,",
			"  PARTITION06,             !- Name",
			"  E1 - 3 / 4 IN PLASTER OR GYP BOARD,  !- Outside Layer",
			"  C6 - 8 IN CLAY TILE,     !- Layer 2",
			"  E1 - 3 / 4 IN PLASTER OR GYP BOARD;  !- Layer 3",
			"  Construction,",
			"  FLOOR SLAB 8 IN,         !- Name",
			"  C10 - 8 IN HW CONCRETE;  !- Outside Layer",
			"Construction,",
			"  ROOF34,                  !- Name",
			"  E2 - 1 / 2 IN SLAG OR STONE,  !- Outside Layer",
			"  E3 - 3 / 8 IN FELT AND MEMBRANE,  !- Layer 2",
			"  B5 - 1 IN DENSE INSULATION,  !- Layer 3",
			"  C12 - 2 IN HW CONCRETE;  !- Layer 4",
			"Construction,",
			"  WIN-CON-LIGHT,           !- Name",
			"  WIN-LAY-GLASS-LIGHT;     !- Outside Layer",
			"Zone,",
			"  WEST_ZONE,               !- Name",
			"  0,                       !- Direction of Relative North {deg}",
			"  0,                       !- X Origin {m}",
			"  0,                       !- Y Origin {m}",
			"  0,                       !- Z Origin {m}",
			"  1,                       !- Type",
			"  1,                       !- Multiplier",
			"  autocalculate;           !- Ceiling Height {m}",
			"Zone,",
			"  EAST_ZONE,               !- Name",
			"  0,                       !- Direction of Relative North {deg}",
			"  0,                       !- X Origin {m}",
			"  0,                       !- Y Origin {m}",
			"  0,                       !- Z Origin {m}",
			"  1,                       !- Type",
			"  1,                       !- Multiplier",
			"  autocalculate;           !- Ceiling Height {m}",
			"Zone,",
			"  NORTH_ZONE,              !- Name",
			"  0,                       !- Direction of Relative North {deg}",
			"  0,                       !- X Origin {m}",
			"  0,                       !- Y Origin {m}",
			"  0,                       !- Z Origin {m}",
			"  1,                       !- Type",
			"  1,                       !- Multiplier",
			"  autocalculate;           !- Ceiling Height {m}",
			"GlobalGeometryRules,",
			"  UpperLeftCorner,         !- Starting Vertex Position",
			"  CounterClockWise,        !- Vertex Entry Direction",
			"  World;                   !- Coordinate System",
			"BuildingSurface:Detailed,",
			"  Surface_1,               !- Name",
			"  WALL,                    !- Surface Type",
			"  EXTWALL80,               !- Construction Name",
			"  WEST_ZONE,               !- Zone Name",
			"  Outdoors,                !- Outside Boundary Condition",
			"  ,                        !- Outside Boundary Condition Object",
			"  SunExposed,              !- Sun Exposure",
			"  WindExposed,             !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  0,0,3.048000,            !- X,Y,Z ==> Vertex 1 {m}",
			"  0,0,0,                   !- X,Y,Z ==> Vertex 2 {m}",
			"  6.096000,0,0,            !- X,Y,Z ==> Vertex 3 {m}",
			"  6.096000,0,3.048000;     !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_2,               !- Name",
			"  WALL,                    !- Surface Type",
			"  EXTWALL80,               !- Construction Name",
			"  WEST_ZONE,               !- Zone Name",
			"  Outdoors,                !- Outside Boundary Condition",
			"  ,                        !- Outside Boundary Condition Object",
			"  SunExposed,              !- Sun Exposure",
			"  WindExposed,             !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  0,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  0,6.096000,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  0,0,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  0,0,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_3,               !- Name",
			"  WALL,                    !- Surface Type",
			"  PARTITION06,             !- Construction Name",
			"  WEST_ZONE,               !- Zone Name",
			"  Surface,                 !- Outside Boundary Condition",
			"  Surface_17,              !- Outside Boundary Condition Object",
			"  NoSun,                   !- Sun Exposure",
			"  NoWind,                  !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  6.096000,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  6.096000,6.096000,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  0,6.096000,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  0,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_4,               !- Name",
			"  WALL,                    !- Surface Type",
			"  PARTITION06,             !- Construction Name",
			"  WEST_ZONE,               !- Zone Name",
			"  Surface,                 !- Outside Boundary Condition",
			"  Surface_10,              !- Outside Boundary Condition Object",
			"  NoSun,                   !- Sun Exposure",
			"  NoWind,                  !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  6.096000,0,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  6.096000,0,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  6.096000,6.096000,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  6.096000,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_5,               !- Name",
			"  FLOOR,                   !- Surface Type",
			"  FLOOR SLAB 8 IN,         !- Construction Name",
			"  WEST_ZONE,               !- Zone Name",
			"  Surface,                 !- Outside Boundary Condition",
			"  Surface_5,               !- Outside Boundary Condition Object",
			"  NoSun,                   !- Sun Exposure",
			"  NoWind,                  !- Wind Exposure",
			"  1.000000,                !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  0,0,0,  !- X,Y,Z ==> Vertex 1 {m}",
			"  0,6.096000,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  6.096000,6.096000,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  6.096000,0,0;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_6,               !- Name",
			"  ROOF,                    !- Surface Type",
			"  ROOF34,                  !- Construction Name",
			"  WEST_ZONE,               !- Zone Name",
			"  Outdoors,                !- Outside Boundary Condition",
			"  ,                        !- Outside Boundary Condition Object",
			"  SunExposed,              !- Sun Exposure",
			"  WindExposed,             !- Wind Exposure",
			"  0,                       !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  0,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  0,0,3.048000,  !- X,Y,Z ==> Vertex 2 {m}",
			"  6.096000,0,3.048000,  !- X,Y,Z ==> Vertex 3 {m}",
			"  6.096000,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_8,               !- Name",
			"  WALL,                    !- Surface Type",
			"  EXTWALL80,               !- Construction Name",
			"  EAST_ZONE,               !- Zone Name",
			"  Outdoors,                !- Outside Boundary Condition",
			"  ,                        !- Outside Boundary Condition Object",
			"  SunExposed,              !- Sun Exposure",
			"  WindExposed,             !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  6.096000,0,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  6.096000,0,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  12.19200,0,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  12.19200,0,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_9,               !- Name",
			"  WALL,                    !- Surface Type",
			"  EXTWALL80,               !- Construction Name",
			"  EAST_ZONE,               !- Zone Name",
			"  Outdoors,                !- Outside Boundary Condition",
			"  ,                        !- Outside Boundary Condition Object",
			"  SunExposed,              !- Sun Exposure",
			"  WindExposed,             !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  12.19200,0,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  12.19200,0,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  12.19200,6.096000,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  12.19200,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_10,              !- Name",
			"  WALL,                    !- Surface Type",
			"  PARTITION06,             !- Construction Name",
			"  EAST_ZONE,               !- Zone Name",
			"  Surface,                 !- Outside Boundary Condition",
			"  Surface_4,               !- Outside Boundary Condition Object",
			"  NoSun,                   !- Sun Exposure",
			"  NoWind,                  !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  6.096000,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  6.096000,6.096000,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  6.096000,0,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  6.096001,0,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_11,              !- Name",
			"  WALL,                    !- Surface Type",
			"  PARTITION06,             !- Construction Name",
			"  EAST_ZONE,               !- Zone Name",
			"  Surface,                 !- Outside Boundary Condition",
			"  Surface_18,              !- Outside Boundary Condition Object",
			"  NoSun,                   !- Sun Exposure",
			"  NoWind,                  !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  12.19200,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  12.19200,6.096000,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  6.096000,6.096000,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  6.096000,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_12,              !- Name",
			"  FLOOR,                   !- Surface Type",
			"  FLOOR SLAB 8 IN,         !- Construction Name",
			"  EAST_ZONE,               !- Zone Name",
			"  Surface,                 !- Outside Boundary Condition",
			"  Surface_12,              !- Outside Boundary Condition Object",
			"  NoSun,                   !- Sun Exposure",
			"  NoWind,                  !- Wind Exposure",
			"  1.000000,                !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  6.096000,0,0,  !- X,Y,Z ==> Vertex 1 {m}",
			"  6.096000,6.096000,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  12.19200,6.096000,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  12.19200,0,0;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_13,              !- Name",
			"  ROOF,                    !- Surface Type",
			"  ROOF34,                  !- Construction Name",
			"  EAST_ZONE,               !- Zone Name",
			"  Outdoors,                !- Outside Boundary Condition",
			"  ,                        !- Outside Boundary Condition Object",
			"  SunExposed,              !- Sun Exposure",
			"  WindExposed,             !- Wind Exposure",
			"  0,                       !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  6.096000,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  6.096000,0,3.048000,  !- X,Y,Z ==> Vertex 2 {m}",
			"  12.19200,0,3.048000,  !- X,Y,Z ==> Vertex 3 {m}",
			"  12.19200,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_14,              !- Name",
			"  WALL,                    !- Surface Type",
			"  EXTWALL80,               !- Construction Name",
			"  NORTH_ZONE,              !- Zone Name",
			"  Outdoors,                !- Outside Boundary Condition",
			"  ,                        !- Outside Boundary Condition Object",
			"  SunExposed,              !- Sun Exposure",
			"  WindExposed,             !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  0,12.19200,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  0,12.19200,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  0,6.096000,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  0,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_15,              !- Name",
			"  WALL,                    !- Surface Type",
			"  EXTWALL80,               !- Construction Name",
			"  NORTH_ZONE,              !- Zone Name",
			"  Outdoors,                !- Outside Boundary Condition",
			"  ,                        !- Outside Boundary Condition Object",
			"  SunExposed,              !- Sun Exposure",
			"  WindExposed,             !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  12.19200,12.19200,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  12.19200,12.19200,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  0,12.19200,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  0,12.19200,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_16,              !- Name",
			"  WALL,                    !- Surface Type",
			"  EXTWALL80,               !- Construction Name",
			"  NORTH_ZONE,              !- Zone Name",
			"  Outdoors,                !- Outside Boundary Condition",
			"  ,                        !- Outside Boundary Condition Object",
			"  SunExposed,              !- Sun Exposure",
			"  WindExposed,             !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  12.19200,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  12.19200,6.096000,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  12.19200,12.19200,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  12.19200,12.19200,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_17,              !- Name",
			"  WALL,                    !- Surface Type",
			"  PARTITION06,             !- Construction Name",
			"  NORTH_ZONE,              !- Zone Name",
			"  Surface,                 !- Outside Boundary Condition",
			"  Surface_3,               !- Outside Boundary Condition Object",
			"  NoSun,                   !- Sun Exposure",
			"  NoWind,                  !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  0.000,6.096,3.048,  !- X,Y,Z ==> Vertex 1 {m}",
			"  0.000,6.096,0.000,  !- X,Y,Z ==> Vertex 2 {m}",
			"  6.096,6.096,0.000,  !- X,Y,Z ==> Vertex 3 {m}",
			"  6.096,6.096,3.048;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_18,              !- Name",
			"  WALL,                    !- Surface Type",
			"  PARTITION06,             !- Construction Name",
			"  NORTH_ZONE,              !- Zone Name",
			"  Surface,                 !- Outside Boundary Condition",
			"  Surface_11,              !- Outside Boundary Condition Object",
			"  NoSun,                   !- Sun Exposure",
			"  NoWind,                  !- Wind Exposure",
			"  0.5000000,               !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  6.096000,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  6.096000,6.096000,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  12.19200,6.096000,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  12.19200,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_19,              !- Name",
			"  FLOOR,                   !- Surface Type",
			"  FLOOR SLAB 8 IN,         !- Construction Name",
			"  NORTH_ZONE,              !- Zone Name",
			"  Surface,                 !- Outside Boundary Condition",
			"  Surface_19,              !- Outside Boundary Condition Object",
			"  NoSun,                   !- Sun Exposure",
			"  NoWind,                  !- Wind Exposure",
			"  1.000000,                !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  0,6.096000,0,  !- X,Y,Z ==> Vertex 1 {m}",
			"  0,12.19200,0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  12.19200,12.19200,0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  12.19200,6.096000,0;  !- X,Y,Z ==> Vertex 4 {m}",
			"BuildingSurface:Detailed,",
			"  Surface_20,              !- Name",
			"  ROOF,                    !- Surface Type",
			"  ROOF34,                  !- Construction Name",
			"  NORTH_ZONE,              !- Zone Name",
			"  Outdoors,                !- Outside Boundary Condition",
			"  ,                        !- Outside Boundary Condition Object",
			"  SunExposed,              !- Sun Exposure",
			"  WindExposed,             !- Wind Exposure",
			"  0,                       !- View Factor to Ground",
			"  4,                       !- Number of Vertices",
			"  0,12.19200,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  0,6.096000,3.048000,  !- X,Y,Z ==> Vertex 2 {m}",
			"  12.19200,6.096000,3.048000,  !- X,Y,Z ==> Vertex 3 {m}",
			"  12.19200,12.19200,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
			/*"FenestrationSurface:Detailed,",
			"  WINDOW11,                !- Name",
			"  WINDOW,                  !- Surface Type",
			"  WIN-CON-LIGHT,           !- Construction Name",
			"  Surface_1,               !- Building Surface Name",
			"  ,                        !- Outside Boundary Condition Object",
			"  0.5000000,               !- View Factor to Ground",
			"  ,                        !- Shading Control Name",
			"  ,                        !- Frame and Divider Name",
			"  1.0,                     !- Multiplier",
			"  3,                       !- Number of Vertices",
			"  1.00000,0,2.500000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  1.00000,0,1.0000000,  !- X,Y,Z ==> Vertex 2 {m}",
			"  5.000000,0,1.0000000;  !- X,Y,Z ==> Vertex 3 {m}",
			"FenestrationSurface:Detailed,",
			"  WINDOW12,                !- Name",
			"  WINDOW,                  !- Surface Type",
			"  WIN-CON-LIGHT,           !- Construction Name",
			"  Surface_1,               !- Building Surface Name",
			"  ,                        !- Outside Boundary Condition Object",
			"  0.5000000,               !- View Factor to Ground",
			"  ,                        !- Shading Control Name",
			"  ,                        !- Frame and Divider Name",
			"  1.0,                     !- Multiplier",
			"  3,                       !- Number of Vertices",
			"  5.00000,0,1.0000000,  !- X,Y,Z ==> Vertex 2 {m}",
			"  5.000000,0,2.5000000,  !- X,Y,Z ==> Vertex 3 {m}",
			"  1.000000,0,2.500000;  !- X,Y,Z ==> Vertex 4 {m}",
			"FenestrationSurface:Detailed,",
			"  DoorInSurface_3,         !- Name",
			"  DOOR,                    !- Surface Type",
			"  DOOR-CON,                !- Construction Name",
			"  Surface_3,               !- Building Surface Name",
			"  DoorInSurface_17,        !- Outside Boundary Condition Object",
			"  0.5000000,               !- View Factor to Ground",
			"  ,                        !- Shading Control Name",
			"  ,                        !- Frame and Divider Name",
			"  1.0,                     !- Multiplier",
			"  4,                       !- Number of Vertices",
			"  3.500,6.096000,2.0,  !- X,Y,Z ==> Vertex 1 {m}",
			"  3.500,6.096000,0.0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  2.500,6.096000,0.0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  2.500,6.096000,2.0;  !- X,Y,Z ==> Vertex 4 {m}",
			"FenestrationSurface:Detailed,",
			"  WINDOW2,                 !- Name",
			"  WINDOW,                  !- Surface Type",
			"  WIN-CON-LIGHT,           !- Construction Name",
			"  Surface_15,              !- Building Surface Name",
			"  ,                        !- Outside Boundary Condition Object",
			"  0.5000000,               !- View Factor to Ground",
			"  ,                        !- Shading Control Name",
			"  ,                        !- Frame and Divider Name",
			"  1.0,                     !- Multiplier",
			"  4,                       !- Number of Vertices",
			"  6.000000,12.19200,2.333000,  !- X,Y,Z ==> Vertex 1 {m}",
			"  6.000000,12.19200,1.000000,  !- X,Y,Z ==> Vertex 2 {m}",
			"  3.000000,12.19200,1.000000,  !- X,Y,Z ==> Vertex 3 {m}",
			"  3.000000,12.19200,2.333000;  !- X,Y,Z ==> Vertex 4 {m}",
			"FenestrationSurface:Detailed,",
			"  DoorInSurface_17,        !- Name",
			"  DOOR,                    !- Surface Type",
			"  DOOR-CON,                !- Construction Name",
			"  Surface_17,              !- Building Surface Name",
			"  DoorInSurface_3,         !- Outside Boundary Condition Object",
			"  0.5000000,               !- View Factor to Ground",
			"  ,                        !- Shading Control Name",
			"  ,                        !- Frame and Divider Name",
			"  1.0,                     !- Multiplier",
			"  4,                       !- Number of Vertices",
			"  2.500,6.096000,2.0,  !- X,Y,Z ==> Vertex 1 {m}",
			"  2.500,6.096000,0.0,  !- X,Y,Z ==> Vertex 2 {m}",
			"  3.500,6.096000,0.0,  !- X,Y,Z ==> Vertex 3 {m}",
			"  3.500,6.096000,2.0;  !- X,Y,Z ==> Vertex 4 {m}",*/
			"AirflowNetwork:SimulationControl,",
			"  NaturalVentilation,      !- Name",
			"  MultizoneWithoutDistribution,  !- AirflowNetwork Control",
			"  INPUT,                   !- Wind Pressure Coefficient Type",
			"  ExternalNode,            !- Height Selection for Local Wind Pressure Calculation",
			"  LOWRISE,                 !- Building Type",
			"  500,                     !- Maximum Number of Iterations {dimensionless}",
			"  ZeroNodePressures,       !- Initialization Type",
			"  1.0E-05,                 !- Relative Airflow Convergence Tolerance {dimensionless}",
			"  1.0E-06,                 !- Absolute Airflow Convergence Tolerance {kg/s}",
			"  -0.5,                    !- Convergence Acceleration Limit {dimensionless}",
			"  0.0,                     !- Azimuth Angle of Long Axis of Building {deg}",
			"  1.0;                     !- Ratio of Building Width Along Short Axis to Width Along Long Axis",
			"AirflowNetwork:MultiZone:Zone,",
			"  WEST_ZONE,               !- Zone Name",
			"  NoVent,                  !- Ventilation Control Mode",
			"  ,                        !- Ventilation Control Zone Temperature Setpoint Schedule Name",
			//"  Temperature,             !- Ventilation Control Mode",
			//"  WindowVentSched,         !- Ventilation Control Zone Temperature Setpoint Schedule Name",
			"  0.3,                     !- Minimum Venting Open Factor {dimensionless}",
			"  5.0,                     !- Indoor and Outdoor Temperature Difference Lower Limit For Maximum Venting Open Factor {deltaC}",
			"  10.0,                    !- Indoor and Outdoor Temperature Difference Upper Limit for Minimum Venting Open Factor {deltaC}",
			"  0.0,                     !- Indoor and Outdoor Enthalpy Difference Lower Limit For Maximum Venting Open Factor {deltaJ/kg}",
			"  300000.0;                !- Indoor and Outdoor Enthalpy Difference Upper Limit for Minimum Venting Open Factor {deltaJ/kg}",
			"AirflowNetwork:MultiZone:Zone,",
			"  EAST_ZONE,               !- Zone Name",
			"  NoVent,                  !- Ventilation Control Mode",
			"  ,                        !- Ventilation Control Zone Temperature Setpoint Schedule Name",
			"  1.0,                     !- Minimum Venting Open Factor {dimensionless}",
			"  0.0,                     !- Indoor and Outdoor Temperature Difference Lower Limit For Maximum Venting Open Factor {deltaC}",
			"  100.0,                   !- Indoor and Outdoor Temperature Difference Upper Limit for Minimum Venting Open Factor {deltaC}",
			"  0.0,                     !- Indoor and Outdoor Enthalpy Difference Lower Limit For Maximum Venting Open Factor {deltaJ/kg}",
			"  300000.0;                !- Indoor and Outdoor Enthalpy Difference Upper Limit for Minimum Venting Open Factor {deltaJ/kg}",
			"AirflowNetwork:MultiZone:Zone,",
			"  NORTH_ZONE,              !- Zone Name",
			"  NoVent,                  !- Ventilation Control Mode",
			"  ,                        !- Ventilation Control Zone Temperature Setpoint Schedule Name",
			//"  Temperature,             !- Ventilation Control Mode",
			//"  WindowVentSched,         !- Ventilation Control Zone Temperature Setpoint Schedule Name",
			"  1.0,                     !- Minimum Venting Open Factor {dimensionless}",
			"  0.0,                     !- Indoor and Outdoor Temperature Difference Lower Limit For Maximum Venting Open Factor {deltaC}",
			"  100.0,                   !- Indoor and Outdoor Temperature Difference Upper Limit for Minimum Venting Open Factor {deltaC}",
			"  0.0,                     !- Indoor and Outdoor Enthalpy Difference Lower Limit For Maximum Venting Open Factor {deltaJ/kg}",
			"  300000.0;                !- Indoor and Outdoor Enthalpy Difference Upper Limit for Minimum Venting Open Factor {deltaJ/kg}",
			"AirflowNetwork:MultiZone:Surface,",
			"  Surface_1,               !- Surface Name",
			"  CR-1,                    !- Leakage Component Name",
			"  SFacade,                 !- External Node Name",
			"  1.0;                     !- Window/Door Opening Factor, or Crack Factor {dimensionless}",
			"AirflowNetwork:MultiZone:Surface,",
			"  Surface_4,               !- Surface Name",
			"  CR-1,                    !- Leakage Component Name",
			"  ,                        !- External Node Name",
			"  1.0;                     !- Window / Door Opening Factor, or Crack Factor{ dimensionless }",
			"AirflowNetwork:MultiZone:Surface,",
			"  Surface_11,              !- Surface Name",
			"  CR-1,                    !- Leakage Component Name",
			"  ,                        !- External Node Name",
			"  1.0;                     !- Window / Door Opening Factor, or Crack Factor{ dimensionless }",
			"AirflowNetwork:MultiZone:Surface,",
			"  Surface_15,              !- Surface Name",
			"  CR-1,                    !- Leakage Component Name",
			"  NFacade,                 !- External Node Name",
			"  1.0;                     !- Window / Door Opening Factor, or Crack Factor{ dimensionless }",
			"AirflowNetwork:MultiZone:ExternalNode,",
			"  NFacade,                 !- Name",
			"  1.524,                   !- External Node Height{ m }",
			"  NFacade_WPCValue;        !- Wind Pressure Coefficient Values Object Name",
			"AirflowNetwork:MultiZone:ExternalNode,",
			"  SFacade,                 !- Name",
			"  1.524,                   !- External Node Height{ m }",
			"  SFacade_WPCValue,        !- Wind Pressure Coefficient Values Object Name",
			"  No,                      !- Symmetric Wind Pressure Coefficient Curve",
			"  Absolute;                !- Wind Angle Type",
			"AirflowNetwork:MultiZone:ReferenceCrackConditions,",
			"  ReferenceCrackConditions,!- Name",
			"  20.0,                    !- Reference Temperature{ C }",
			"  101320,                  !- Reference Barometric Pressure{ Pa }",
			"  0.005;                   !- Reference Humidity Ratio{ kgWater / kgDryAir }",
			"AirflowNetwork:MultiZone:Surface:Crack,",
			"  CR-1,                    !- Name",
			"  0.01,                    !- Air Mass Flow Coefficient at Reference Conditions{ kg / s }",
			"  0.667,                   !- Air Mass Flow Exponent{ dimensionless }",
			"  ReferenceCrackConditions;!- Reference Crack Conditions",
			"AirflowNetwork:MultiZone:WindPressureCoefficientArray,",
			"  Every 30 Degrees,        !- Name",
			"  0,                       !- Wind Direction 1 {deg}",
			"  30,                      !- Wind Direction 2 {deg}",
			"  60,                      !- Wind Direction 3 {deg}",
			"  90,                      !- Wind Direction 4 {deg}",
			"  120,                     !- Wind Direction 5 {deg}",
			"  150,                     !- Wind Direction 6 {deg}",
			"  180,                     !- Wind Direction 7 {deg}",
			"  210,                     !- Wind Direction 8 {deg}",
			"  240,                     !- Wind Direction 9 {deg}",
			"  270,                     !- Wind Direction 10 {deg}",
			"  300,                     !- Wind Direction 11 {deg}",
			"  330;                     !- Wind Direction 12 {deg}",
			"AirflowNetwork:MultiZone:WindPressureCoefficientValues,",
			"  NFacade_WPCValue,        !- Name",
			"  Every 30 Degrees,        !- AirflowNetwork:MultiZone:WindPressureCoefficientArray Name",
			"  0.60,                    !- Wind Pressure Coefficient Value 1 {dimensionless}",
			"  0.48,                    !- Wind Pressure Coefficient Value 2 {dimensionless}",
			"  0.04,                    !- Wind Pressure Coefficient Value 3 {dimensionless}",
			"  -0.56,                   !- Wind Pressure Coefficient Value 4 {dimensionless}",
			"  -0.56,                   !- Wind Pressure Coefficient Value 5 {dimensionless}",
			"  -0.42,                   !- Wind Pressure Coefficient Value 6 {dimensionless}",
			"  -0.37,                   !- Wind Pressure Coefficient Value 7 {dimensionless}",
			"  -0.42,                   !- Wind Pressure Coefficient Value 8 {dimensionless}",
			"  -0.56,                   !- Wind Pressure Coefficient Value 9 {dimensionless}",
			"  -0.56,                   !- Wind Pressure Coefficient Value 10 {dimensionless}",
			"  0.04,                    !- Wind Pressure Coefficient Value 11 {dimensionless}",
			"  0.48;                    !- Wind Pressure Coefficient Value 12 {dimensionless}",
			"AirflowNetwork:MultiZone:WindPressureCoefficientValues,",
			"  SFacade_WPCValue,        !- Name",
			"  Every 30 Degrees,        !- AirflowNetwork:MultiZone:WindPressureCoefficientArray Name",
			"  -0.37,                   !- Wind Pressure Coefficient Value 1 {dimensionless}",
			"  -0.42,                   !- Wind Pressure Coefficient Value 2 {dimensionless}",
			"  -0.56,                   !- Wind Pressure Coefficient Value 3 {dimensionless}",
			"  -0.56,                   !- Wind Pressure Coefficient Value 4 {dimensionless}",
			"  0.04,                    !- Wind Pressure Coefficient Value 5 {dimensionless}",
			"  0.48,                    !- Wind Pressure Coefficient Value 6 {dimensionless}",
			"  0.60,                    !- Wind Pressure Coefficient Value 7 {dimensionless}",
			"  0.48,                    !- Wind Pressure Coefficient Value 8 {dimensionless}",
			"  0.04,                    !- Wind Pressure Coefficient Value 9 {dimensionless}",
			"  -0.56,                   !- Wind Pressure Coefficient Value 10 {dimensionless}",
			"  -0.56,                   !- Wind Pressure Coefficient Value 11 {dimensionless}",
			"  -0.42;                   !- Wind Pressure Coefficient Value 12 {dimensionless}",
			"SurfaceConvectionAlgorithm:Inside,TARP;",
			"SurfaceConvectionAlgorithm:Outside,DOE-2;",
			"HeatBalanceAlgorithm,ConductionTransferFunction;",
			"ZoneAirHeatBalanceAlgorithm,",
			"  AnalyticalSolution;      !- Algorithm" });
		ASSERT_FALSE(process_idf(idf_objects));

		bool errors = false;

		HeatBalanceManager::GetMaterialData(errors); // read material data
		EXPECT_FALSE(errors); // expect no errors

		HeatBalanceManager::GetConstructData(errors); // read construction data
		EXPECT_FALSE(errors); // expect no errors

		HeatBalanceManager::GetZoneData(errors); // read zone data
		EXPECT_FALSE(errors); // expect no errors

		// Magic to get surfaces read in correctly
		DataHeatBalance::HeatTransferAlgosUsed.allocate(1);
		DataHeatBalance::HeatTransferAlgosUsed(1) = OverallHeatTransferSolutionAlgo;
		SurfaceGeometry::CosBldgRotAppGonly = 1.0;
		SurfaceGeometry::SinBldgRotAppGonly = 0.0;

		SurfaceGeometry::GetSurfaceData(errors); // setup zone geometry and get zone data
		EXPECT_FALSE(errors); // expect no errors

		CurveManager::GetCurveInput();
		EXPECT_EQ( CurveManager::NumCurves, 2 );

		AirflowNetworkBalanceManager::GetAirflowNetworkInput();

		// Check the airflow elements
		EXPECT_EQ( 2u, DataAirflowNetwork::MultizoneExternalNodeData.size() );
		EXPECT_EQ( 3u, DataAirflowNetwork::MultizoneZoneData.size() );
		EXPECT_EQ( 4u, DataAirflowNetwork::MultizoneSurfaceData.size() );
		EXPECT_EQ( 1u, DataAirflowNetwork::MultizoneSurfaceCrackData.size() );
		EXPECT_EQ( 2u, DataAirflowNetwork::MultizoneSurfaceStdConditionsCrackData.size() );

		EXPECT_EQ( 0.0, DataAirflowNetwork::MultizoneExternalNodeData( 1 ).azimuth );
		EXPECT_FALSE( DataAirflowNetwork::MultizoneExternalNodeData( 1 ).symmetricCurve );
		EXPECT_FALSE( DataAirflowNetwork::MultizoneExternalNodeData( 1 ).useRelativeAngle );
		EXPECT_EQ( 1, DataAirflowNetwork::MultizoneExternalNodeData( 1 ).curve );

		EXPECT_EQ( 180.0, DataAirflowNetwork::MultizoneExternalNodeData( 2 ).azimuth );
		EXPECT_FALSE( DataAirflowNetwork::MultizoneExternalNodeData( 2 ).symmetricCurve );
		EXPECT_FALSE( DataAirflowNetwork::MultizoneExternalNodeData( 2 ).useRelativeAngle );
		EXPECT_EQ( 2, DataAirflowNetwork::MultizoneExternalNodeData( 2 ).curve );

		// Set up some environmental parameters
		DataEnvironment::OutBaroPress = 101325.0;
		DataEnvironment::OutDryBulbTemp = 25.0;
		DataEnvironment::WindDir = 105.0;
		DataEnvironment::OutHumRat = 0.0; // Dry air only
		DataEnvironment::SiteTempGradient = 0.0; // Disconnect z from testing
		DataEnvironment::SiteWindExp = 0.0; // Disconnect variation by height
		DataEnvironment::WindSpeed = 10.0;

		// Make sure we can compute the right wind pressure
		Real64 rho = Psychrometrics::PsyRhoAirFnPbTdbW( DataEnvironment::OutBaroPress, DataEnvironment::OutDryBulbTemp,
			DataEnvironment::OutHumRat );
		EXPECT_DOUBLE_EQ( 1.1841123742118911, rho );
		Real64 p = AirflowNetworkBalanceManager::CalcWindPressure( DataAirflowNetwork::MultizoneExternalNodeData( 1 ).curve,
			1.0, 0.0, 0.0, false, false );
		EXPECT_DOUBLE_EQ( -0.56*0.5*1.1841123742118911, p );

		// Make sure the reference velocity comes out right
		EXPECT_DOUBLE_EQ( 10.0, DataEnvironment::WindSpeedAt( MultizoneExternalNodeData( 1 ).height) );

		EXPECT_EQ( 5u, DataAirflowNetwork::AirflowNetworkNodeSimu.size() );

		// Run the balance routine, for now only to get the pressure set at the external nodes
		AirflowNetworkBalanceManager::CalcAirflowNetworkAirBalance();

		EXPECT_DOUBLE_EQ( -0.56*0.5*118.41123742118911, DataAirflowNetwork::AirflowNetworkNodeSimu( 4 ).PZ );
		EXPECT_DOUBLE_EQ( -0.26*0.5*118.41123742118911, DataAirflowNetwork::AirflowNetworkNodeSimu( 5 ).PZ );
	}
MLS
