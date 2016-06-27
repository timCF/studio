defmodule StudioTest do
	use ExUnit.Case
	doctest Studio

	defp test_protoc do
		this_dir = "#{Exutils.priv_dir(:studio)}/studio_proto"
		test_protoc_rm(this_dir)
		[] = :os.cmd('protoc #{this_dir}/studio.proto --proto_path=#{this_dir} --cpp_out=#{this_dir}')
		test_protoc_rm(this_dir)
	end
	defp test_protoc_rm(this_dir), do: Enum.each(["studio.pb.h","studio.pb.cc"],&(File.rm(this_dir<>"/"<>&1)))

	test "the truth" do
		test_protoc
		assert 1 + 1 == 2
	end
end
