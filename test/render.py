import numpy as np
from PIL import Image

# Vector operations
def normalize(v):
    return v / np.linalg.norm(v)

def dot(v1, v2):
    return np.dot(v1, v2)

# Ray-sphere intersection
def intersect_sphere(origin, direction, sphere):
    oc = origin - sphere['center']
    a = dot(direction, direction)
    b = 2.0 * dot(oc, direction)
    c = dot(oc, oc) - sphere['radius'] ** 2
    discriminant = b ** 2 - 4 * a * c
    if discriminant < 0:
        return None  # No intersection
    t1 = (-b - np.sqrt(discriminant)) / (2.0 * a)
    t2 = (-b + np.sqrt(discriminant)) / (2.0 * a)
    return min(t1, t2) if t1 > 0 else (t2 if t2 > 0 else None)

# Ray-cylinder intersection
def intersect_cylinder(origin, direction, cylinder):
    # Cylinder's direction should be normalized
    ca = cylinder['direction']
    oc = origin - cylinder['center']
    
    # Calculate the coefficients for the quadratic equation
    a = dot(direction, direction) - dot(direction, ca) ** 2
    b = dot(direction, oc) - dot(direction, ca) * dot(oc, ca)
    c = dot(oc, oc) - dot(oc, ca) ** 2 - cylinder['radius'] ** 2
    discriminant = b ** 2 - a * c
    
    if discriminant < 0:
        return None  # No intersection

    # Solving the quadratic equation
    sqrt_discriminant = np.sqrt(discriminant)
    t1 = (-b - sqrt_discriminant) / a
    t2 = (-b + sqrt_discriminant) / a

    # Find the closest valid intersection
    t = min(t1, t2) if t1 > 0 else (t2 if t2 > 0 else None)
    if t is None:
        return None

    # Check if the intersection point is within the height of the cylinder
    hit_point = origin + direction * t
    height = dot(hit_point - cylinder['center'], ca)
    if 0 <= height <= cylinder['height']:
        return t
    return None

# Main render function with support for spheres and cylinders
def render(camera, spheres, cylinders, lights, width=400, height=300, fov=90):
    aspect_ratio = width / height
    angle = np.tan(np.radians(fov / 2))
    print(angle)
    img = Image.new("RGB", (width, height))
    pixels = img.load()

    for y in range(height):
        for x in range(width):
            # Normalized screen space coordinates
            px = (2 * (x + 0.5) / width - 1) * angle * aspect_ratio
            py = (1 - 2 * (y + 0.5) / height) * angle
            direction = normalize(np.array([px, py, -1]))  # Camera pointing along -z

            # Find nearest intersection
            color = np.array([0, 0, 0])
            min_dist = float('inf')

            # Check intersections with spheres
            for sphere in spheres:
                dist = intersect_sphere(camera, direction, sphere)
                if dist is not None and dist < min_dist:
                    min_dist = dist
                    # Compute point of intersection
                    hit_point = camera + direction * dist
                    normal = normalize(hit_point - sphere['center'])

                    # Accumulate light contribution from each source
                    sphere_color = np.array(sphere['color'])
                    final_color = np.zeros(3)
                    for light in lights:
                        light_dir = normalize(light['position'] - hit_point)
                        intensity = max(dot(normal, light_dir), 0) * light['intensity']
                        final_color += intensity * sphere_color

                    color = np.clip(final_color, 0, 255).astype(int)

            # Check intersections with cylinders
            for cylinder in cylinders:
                dist = intersect_cylinder(camera, direction, cylinder)
                if dist is not None and dist < min_dist:
                    min_dist = dist
                    # Compute point of intersection
                    hit_point = camera + direction * dist
                    hit_height = hit_point[1] - cylinder["center"][1]
                    ca = cylinder['direction']
                    normal = normalize((hit_point - cylinder['center']) - dot(hit_point - cylinder['center'], ca) * ca)

                    # Accumulate light contribution from each source
                    cylinder_color = np.array(cylinder['color'])
                    if 2 < hit_height < 2.2: cylinder_color = np.array([255, 0, 0])
                    final_color = np.zeros(3)
                    for light in lights:
                        light_dir = normalize(light['position'] - hit_point)
                        intensity = max(dot(normal, light_dir), 0) * light['intensity']
                        final_color += intensity * cylinder_color

                    color = np.clip(final_color, 0, 255).astype(int)

            # Set the pixel color
            pixels[x, y] = tuple(color)

    return img

# Define camera, spheres, cylinders, and multiple light sources
camera = np.array([0, 0, 5])
spheres = [
    {'center': np.array([0, -5, -5]), 'radius': 1, 'color': [0, 255, 0]},  # Green sphere
]
cylinders = [
    {'center': np.array([-6, -5, -16]), 'direction': normalize(np.array([0, 1, 0])), 'radius': 0.7, 'height': 3, 'color': [255, 255, 255]},
    {'center': np.array([-2, -5, -16]), 'direction': normalize(np.array([0, 1, 0])), 'radius': 0.7, 'height': 3, 'color': [255, 255, 255]},
    {'center': np.array([2, -5, -16]), 'direction': normalize(np.array([0, 1, 0])), 'radius': 0.7, 'height': 3, 'color': [255, 255, 255]},
    {'center': np.array([6, -5, -16]), 'direction': normalize(np.array([0, 1, 0])), 'radius': 0.7, 'height': 3, 'color': [255, 255, 255]},
    {'center': np.array([-4, -5, -14]), 'direction': normalize(np.array([0, 1, 0])), 'radius': 0.7, 'height': 3, 'color': [255, 255, 255]},
    {'center': np.array([0, -5, -14]), 'direction': normalize(np.array([0, 1, 0])), 'radius': 0.7, 'height': 3, 'color': [255, 255, 255]},
    {'center': np.array([4, -5, -14]), 'direction': normalize(np.array([0, 1, 0])), 'radius': 0.7, 'height': 3, 'color': [255, 255, 255]},
    {'center': np.array([-2, -5, -12]), 'direction': normalize(np.array([0, 1, 0])), 'radius': 0.7, 'height': 3, 'color': [255, 255, 255]},
    {'center': np.array([2, -5, -12]), 'direction': normalize(np.array([0, 1, 0])), 'radius': 0.7, 'height': 3, 'color': [255, 255, 255]},
    {'center': np.array([0, -5, -10]), 'direction': normalize(np.array([0, 1, 0])), 'radius': 0.7, 'height': 3, 'color': [255, 255, 255]},
]
lights = [
    {'position': np.array([0, 10, 10]), 'intensity': 0.7},
    {'position': np.array([0, 10, -5]), 'intensity': 0.5},
]

# Render and save the image
image = render(camera, spheres, cylinders, lights, width=640, height=320)
image.show()
