#!/usr/bin/env python3
"""Simple GPU stress test using PyTorch matrix multiplications."""

import time
import argparse

try:
    import torch
except ImportError:
    print("PyTorch not installed. Run: pip install torch")
    exit(1)

def stress_gpu(duration=60, size=4096):
    if not torch.cuda.is_available():
        print("CUDA not available!")
        return
    
    device = torch.device("cuda")
    print(f"Using GPU: {torch.cuda.get_device_name(0)}")
    print(f"Running for {duration} seconds with matrix size {size}x{size}")
    
    # Create large matrices on GPU
    a = torch.randn(size, size, device=device)
    b = torch.randn(size, size, device=device)
    
    start = time.time()
    iterations = 0
    
    try:
        while time.time() - start < duration:
            # Matrix multiplication is GPU-intensive
            c = torch.mm(a, b)
            torch.cuda.synchronize()
            iterations += 1
            
            if iterations % 100 == 0:
                elapsed = time.time() - start
                print(f"Iterations: {iterations}, Elapsed: {elapsed:.1f}s")
    except KeyboardInterrupt:
        print("\nStopped by user")
    
    print(f"Completed {iterations} iterations in {time.time() - start:.1f}s")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GPU stress test")
    parser.add_argument("-d", "--duration", type=int, default=60, help="Duration in seconds")
    parser.add_argument("-s", "--size", type=int, default=4096, help="Matrix size")
    args = parser.parse_args()
    
    stress_gpu(args.duration, args.size)
