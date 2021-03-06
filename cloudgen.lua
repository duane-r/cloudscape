-- Cloudscape cloudgen.lua
-- Copyright Duane Robertson (duane@duanerobertson.com), 2017
-- Distributed under the LGPLv2.1 (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)


local node = cloudscape.node


local cloud_noise_1 = {offset = 10, scale = 10, seed = 4877, spread = {x = 120, y = 120, z = 120}, octaves = 3, persist = 1, lacunarity = 2}
local cloud_noise_2 = {offset = 0, scale = 1, seed = 5748, spread = {x = 40, y = 10, z = 40}, octaves = 3, persist = 1, lacunarity = 2}
local plant_noise = {offset = 0.0, scale = 1.0, spread = {x = 200, y = 200, z = 200}, seed = -2525, octaves = 3, persist = 0.7, lacunarity = 2.0}
local biome_noise = {offset = 0.0, scale = 1.0, spread = {x = 400, y = 400, z = 400}, seed = -1471, octaves = 3, persist = 0.5, lacunarity = 2.0}

local cloud_1_map, cloud_2_map, plant_n_map, biome_n_map
local cloud_1, cloud_2, plant_n, biome_n = {}, {}, {}, {}


cloudscape.cloudgen = function(minp, maxp, data, p2data, area)
  if not (minp and maxp and data and p2data and area and type(data) == 'table' and type(p2data) == 'table' and cloudscape.place_schematic and cloudscape.schematics and cloudscape.surround) then
    return
  end

  do
    local avg = (minp.y + maxp.y) / 2
    avg = math.floor(avg / csize.y)
    if avg ~= cloudscape.height then
      return
    end
  end

  local csize = vector.add(vector.subtract(maxp, minp), 1)
  local map_max = {x = csize.x, y = csize.y, z = csize.z}
  local map_min = {x = minp.x, y = minp.y, z = minp.z}

  if not (cloud_1_map and cloud_2_map and plant_n_map and biome_n_map) then
    cloud_1_map = minetest.get_perlin_map(cloud_noise_1, {x=csize.x, y=csize.z})
    cloud_2_map = minetest.get_perlin_map(cloud_noise_2, map_max)
    plant_n_map = minetest.get_perlin_map(plant_noise, {x=csize.x, y=csize.z})
    biome_n_map = minetest.get_perlin_map(biome_noise, {x=csize.x, y=csize.z})

    if not (cloud_1_map and cloud_2_map and plant_n_map and biome_n_map) then
      return
    end
  end

  cloud_1 = cloud_1_map:get2dMap_flat({x=minp.x, y=minp.z})
  cloud_2 = cloud_2_map:get3dMap_flat(map_min)
  plant_n = plant_n_map:get2dMap_flat({x=minp.x, y=minp.z})
  biome_n = biome_n_map:get2dMap_flat({x=minp.x, y=minp.z})

  if not (cloud_1 and cloud_2 and plant_n and biome_n) then
    return
  end

  local write = false

  local index = 0
  local index3d = 0
  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      index = index + 1
      index3d = (z - minp.z) * (csize.y) * csize.x + (x - minp.x) + 1
      local ivm = area:index(x, minp.y, z)

      local cloud
      if biome_n[index] < 0 then
        cloud = 'storm_cloud'
      else
        cloud = 'cloud'
      end

      cloud_1[index] = math.floor(cloud_1[index] + 0.5)
      for y = minp.y, maxp.y do
        local dy = y - minp.y
        if dy > 32 and cloud_1[index] > 15 and dy < 47 then
          if dy < 48 - (cloud_1[index] - 15) then
            if cloud == 'cloud' and math.random(10000) == 1 then
              data[ivm] = node['cloudscape:silver_lining']
            else
              data[ivm] = node['cloudscape:'..cloud]
            end
          else
            data[ivm] = node['default:water_source']
            write = true
          end
        elseif cloud_1[index] > 0 and (dy <= 32 or cloud_1[index] <= 15) and dy >= 32 - cloud_1[index] and dy <= 32 + cloud_1[index] then
          if cloud == 'cloud' and math.random(10000) == 1 then
            data[ivm] = node['cloudscape:silver_lining']
          else
            data[ivm] = node['cloudscape:'..cloud]
          end
          write = true
        elseif data[ivm - area.ystride] == node['cloudscape:'..cloud] and data[ivm] == node['air'] then
          if math.random(30) == 1 and plant_n[index] > 0.5 then
            data[ivm] = node['cloudscape:moon_weed']
            write = true
          elseif math.random(60) == 1 and plant_n[index] > 0.5 then
            cloudscape.place_schematic(minp, maxp, data, p2data, area, node, {x=x,y=y,z=z}, cloudscape.schematics['lumin_tree'], true)
            write = true
          elseif math.random(10) == 1 then
            data[ivm] = node['default:grass_'..math.random(4)]
            write = true
          end
        elseif data[ivm] == node['air'] and (dy < 29 - cloud_1[index] or dy > 35 + cloud_1[index]) and cloud_2[index3d] > math.abs((dy - 40) / 20) then
          data[ivm] = node['cloudscape:wispy_cloud']
          write = true
        end

        ivm = ivm + area.ystride
        index3d = index3d + csize.x
      end
    end
  end

  local index = 0
  local index3d = 0
  for z = minp.z, maxp.z do
    for x = minp.x, maxp.x do
      index = index + 1
      local ivm = area:index(x, minp.y, z)

      local cloud
      if biome_n[index] < 0 then
        cloud = 'storm_cloud'
      else
        cloud = 'cloud'
      end

      cloud_1[index] = math.floor(cloud_1[index] + 0.5)
      if cloud_1[index] > 0 then
        for y = minp.y, maxp.y do
          local dy = y - minp.y
          if data[ivm] == node['cloudscape:'..cloud] and data[ivm + area.ystride] == node['default:water_source'] and math.random(30) == 1 and cloudscape.surround(node, data, area, ivm) then
            data[ivm] = node['cloudscape:water_plant_1_water_'..cloud]
          end

          ivm = ivm + area.ystride
        end
      end
    end
  end

  return write
end
